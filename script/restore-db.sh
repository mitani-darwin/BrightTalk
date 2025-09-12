#!/bin/bash

# データベースリストア専用スクリプト for BrightTalk
# S3からSQLite3データベースをリストア

set -e  # エラー時に停止

# 色付きログ出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 設定値
AWS_REGION="ap-northeast-1"
S3_BUCKET="brighttalk-db-backup"

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_highlight() {
    echo -e "${CYAN}[SELECT]${NC} $1"
}

# 必要なツールのチェック
check_prerequisites() {
    echo_info "必要なツールをチェック中..."

    if ! command -v aws &> /dev/null; then
        echo_error "AWS CLIが見つかりません。インストールしてください。"
        exit 1
    fi

    if ! command -v ssh &> /dev/null; then
        echo_error "SSHが見つかりません。"
        exit 1
    fi

    # SSH_KEY_PATHの設定確認
    if [ -z "$SSH_KEY_PATH" ]; then
        echo_warning "SSH_KEY_PATHが設定されていません。terraform/ssh-keys/mac-mini-2023.local-ed25519-keyを使用します。"
        export SSH_KEY_PATH="terraform/ssh-keys/mac-mini-2023.local-ed25519-key"
    fi

    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo_error "SSH秘密鍵が見つかりません: $SSH_KEY_PATH"
        exit 1
    fi

    echo_success "前提条件のチェック完了"
}

# S3から利用可能なバックアップ日付を取得
list_backup_dates() {
    echo_info "S3から利用可能なバックアップ日付を取得中..."
    
    local dates=($(aws s3 ls "s3://$S3_BUCKET/" --region $AWS_REGION | grep "PRE" | awk '{print $2}' | sed 's|/||g' | sort -r))
    
    if [ ${#dates[@]} -eq 0 ]; then
        echo_error "バックアップが見つかりません: s3://$S3_BUCKET/"
        exit 1
    fi
    
    echo_info "利用可能なバックアップ日付:"
    for i in "${!dates[@]}"; do
        echo_highlight "  $((i+1)). ${dates[i]}"
    done
    
    echo "${dates[@]}"
}

# 特定日付のバックアップファイルを取得
list_backup_files() {
    local date_dir="$1"
    
    echo_info "$date_dir のバックアップファイルを取得中..."
    
    local files=($(aws s3 ls "s3://$S3_BUCKET/$date_dir/" --region $AWS_REGION | grep "\.gz$" | awk '{print $4}' | sort))
    
    if [ ${#files[@]} -eq 0 ]; then
        echo_error "指定された日付にバックアップファイルが見つかりません: $date_dir"
        exit 1
    fi
    
    echo_info "$date_dir の利用可能なバックアップファイル:"
    for i in "${!files[@]}"; do
        echo_highlight "  $((i+1)). ${files[i]}"
    done
    
    echo "${files[@]}"
}

# バックアップファイルの詳細情報を表示
show_backup_info() {
    local date_dir="$1"
    
    echo_info "$date_dir のバックアップ詳細情報:"
    aws s3 ls "s3://$S3_BUCKET/$date_dir/" --region $AWS_REGION --human-readable --summarize | while read line; do
        if [[ "$line" == *".gz"* ]]; then
            echo_info "  $line"
        fi
    done
}

# データベースリストア
restore_database() {
    local date_dir="$1"
    local selected_files=("${@:2}")
    
    echo_info "データベースリストアを開始..."
    echo_info "日付: $date_dir"
    echo_info "対象ファイル: ${selected_files[*]}"
    
    # 現在動作中のコンテナ名を取得
    local container_name=$(ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker ps --filter label=service=bright_talk --filter label=role=web --format '{{.Names}}' | head -1")
    
    if [ -z "$container_name" ]; then
        echo_error "コンテナが見つかりません"
        exit 1
    fi
    
    echo_info "使用するコンテナ: $container_name"
    
    # 確認プロンプト
    echo_warning "⚠️  データベースリストアは現在のデータを上書きします。"
    echo_warning "⚠️  必ず現在のデータベースのバックアップを取ってから実行してください。"
    echo ""
    read -t 120 -p "本当にリストアを実行しますか？ (yes/no): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        echo_info "リストア処理をキャンセルしました。"
        exit 0
    fi
    
    local restored_files=()
    local temp_dir=$(mktemp -d)
    
    for compressed_filename in "${selected_files[@]}"; do
        echo_info "$compressed_filename をリストア中..."
        
        # S3からファイルをダウンロード
        local temp_compressed="$temp_dir/$compressed_filename"
        echo_info "S3からダウンロード中: s3://$S3_BUCKET/$date_dir/$compressed_filename"
        
        if aws s3 cp "s3://$S3_BUCKET/$date_dir/$compressed_filename" "$temp_compressed" --region $AWS_REGION; then
            echo_info "ダウンロード成功 ($(wc -c < "$temp_compressed") bytes)"
            
            # ファイル名から元のデータベース名を抽出
            local db_name=$(echo "$compressed_filename" | sed 's/_backup_[0-9]*_[0-9]*.sqlite3.gz$//')
            local target_db="/rails/storage/${db_name}.sqlite3"
            local temp_uncompressed="${temp_compressed%.gz}"
            
            echo_info "圧縮ファイルを展開中..."
            if gunzip -c "$temp_compressed" > "$temp_uncompressed" 2>/dev/null; then
                echo_info "展開成功 ($(wc -c < "$temp_uncompressed") bytes)"
                
                # コンテナ内にファイルを転送
                echo_info "コンテナ内にファイルを転送中..."
                if cat "$temp_uncompressed" | ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec -i $container_name sh -c 'cat > /tmp/restore_$(basename $temp_uncompressed)'"; then
                    
                    local temp_container_file="/tmp/restore_$(basename $temp_uncompressed)"
                    
                    # アプリケーションを一時停止（オプション）
                    echo_info "データベースファイルを置換中..."
                    
                    # 現在のデータベースをバックアップ
                    ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name cp $target_db ${target_db}.pre-restore-backup 2>/dev/null || true"
                    
                    # ファイルを置換
                    if ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name cp $temp_container_file $target_db"; then
                        echo_success "$db_name.sqlite3 のリストア完了"
                        restored_files+=("$db_name.sqlite3")
                        
                        # 権限を修正
                        ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name chown rails:rails $target_db" 2>/dev/null || true
                        ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name chmod 644 $target_db" 2>/dev/null || true
                        
                    else
                        echo_error "$db_name.sqlite3 のリストアに失敗しました"
                        # バックアップから復元を試行
                        ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name cp ${target_db}.pre-restore-backup $target_db 2>/dev/null || true"
                    fi
                    
                    # 一時ファイルをクリーンアップ
                    ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name rm -f $temp_container_file" 2>/dev/null
                    
                else
                    echo_error "$compressed_filename のコンテナ転送に失敗しました"
                fi
                
                rm -f "$temp_uncompressed"
            else
                echo_error "$compressed_filename の展開に失敗しました"
            fi
            
            rm -f "$temp_compressed"
        else
            echo_error "$compressed_filename のS3ダウンロードに失敗しました"
        fi
    done
    
    # 一時ディレクトリをクリーンアップ
    rm -rf "$temp_dir"
    
    if [ ${#restored_files[@]} -gt 0 ]; then
        echo_success "データベースリストア完了: ${#restored_files[@]}個のファイルをリストア"
        for file in "${restored_files[@]}"; do
            echo_info "  - $file"
        done
        
        echo ""
        echo_warning "⚠️  アプリケーションの再起動を推奨します:"
        echo_info "  kamal app restart"
        
    else
        echo_error "リストア処理に失敗しました"
        exit 1
    fi
}

# ヘルプ表示
show_help() {
    echo "使用方法: $0 [OPTIONS] [DATE]"
    echo ""
    echo "BrightTalkのSQLite3データベースをS3からリストアします"
    echo ""
    echo "OPTIONS:"
    echo "  -l, --list      利用可能なバックアップ日付を表示"
    echo "  -d, --date DATE 特定の日付のバックアップを表示 (YYYY-MM-DD形式)"
    echo "  -f, --file FILE 特定のファイルのみをリストア"
    echo "  -a, --all       指定日付のすべてのファイルをリストア"
    echo "  -h, --help      このヘルプを表示"
    echo ""
    echo "環境変数:"
    echo "  SSH_KEY_PATH    SSH秘密鍵のパス (デフォルト: terraform/ssh-keys/mac-mini-2023.local-ed25519-key)"
    echo ""
    echo "例:"
    echo "  $0 -l                           # 利用可能な日付を表示"
    echo "  $0 -d 2025-01-15                # 特定日付のバックアップファイルを表示"
    echo "  $0 -d 2025-01-15 -a             # 特定日付のすべてをリストア"
    echo "  $0 -d 2025-01-15 -f production.sqlite3  # 特定ファイルのみリストア"
    echo "  $0 2025-01-15                   # インタラクティブモード"
}

# メイン処理
main() {
    echo_info "🔄 BrightTalk データベースリストアスクリプト開始"
    echo_info "S3バケット: $S3_BUCKET"
    echo_info "リージョン: $AWS_REGION"
    echo ""

    local list_only=false
    local target_date=""
    local target_file=""
    local restore_all=false

    # 引数の処理
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--list)
                list_only=true
                shift
                ;;
            -d|--date)
                target_date="$2"
                shift 2
                ;;
            -f|--file)
                target_file="$2"
                shift 2
                ;;
            -a|--all)
                restore_all=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    target_date="$1"
                else
                    echo_error "不明なオプション: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 処理実行
    check_prerequisites

    if [ "$list_only" = true ]; then
        list_backup_dates > /dev/null
        exit 0
    fi

    if [ -n "$target_date" ]; then
        # 日付が指定された場合
        if [ "$restore_all" = true ]; then
            # すべてのファイルをリストア
            local files=($(list_backup_files "$target_date"))
            restore_database "$target_date" "${files[@]}"
        elif [ -n "$target_file" ]; then
            # 特定ファイルのみリストア
            local files=($(list_backup_files "$target_date"))
            local found_file=""
            for file in "${files[@]}"; do
                if [[ "$file" =~ ${target_file}.*\.gz$ ]]; then
                    found_file="$file"
                    break
                fi
            done
            if [ -n "$found_file" ]; then
                restore_database "$target_date" "$found_file"
            else
                echo_error "指定されたファイルが見つかりません: $target_file"
                exit 1
            fi
        else
            # ファイル選択モード
            show_backup_info "$target_date"
            echo ""
            
            # ファイルリストを取得（表示も含む）
            local files_output=$(list_backup_files "$target_date")
            local files=($(echo "$files_output" | tail -n 1))
            
            echo ""
            read -p "リストアするファイル番号を選択してください (1-${#files[@]}, a=全て, q=終了): " choice
            
            case "$choice" in
                q|Q)
                    echo_info "リストア処理をキャンセルしました。"
                    exit 0
                    ;;
                a|A)
                    restore_database "$target_date" "${files[@]}"
                    ;;
                [0-9]*)
                    if [ "$choice" -ge 1 ] && [ "$choice" -le ${#files[@]} ]; then
                        local selected_file="${files[$((choice-1))]}"
                        restore_database "$target_date" "$selected_file"
                    else
                        echo_error "無効な選択です: $choice"
                        exit 1
                    fi
                    ;;
                *)
                    echo_error "無効な選択です: $choice"
                    exit 1
                    ;;
            esac
        fi
    else
        # インタラクティブモード（日付選択から開始）
        # 表示用の呼び出し
        list_backup_dates >&2
        # 配列取得用の呼び出し
        local dates=($(aws s3 ls "s3://$S3_BUCKET/" --region $AWS_REGION | grep "PRE" | awk '{print $2}' | sed 's|/||g' | sort -r))
        echo ""
        read -t 120 -p "リストアする日付を番号で選択してください (1-${#dates[@]}, q=終了): " date_choice
        
        case "$date_choice" in
            q|Q)
                echo_info "リストア処理をキャンセルしました。"
                exit 0
                ;;
            [0-9]*)
                if [ "$date_choice" -ge 1 ] && [ "$date_choice" -le ${#dates[@]} ]; then
                    local selected_date="${dates[$((date_choice-1))]}"
                    show_backup_info "$selected_date"
                    echo ""
                    local files=($(list_backup_files "$selected_date"))
                    echo ""
                    read -t 120 -p "リストアするファイル番号を選択してください (1-${#files[@]}, a=全て, q=終了): " file_choice
                    
                    case "$file_choice" in
                        q|Q)
                            echo_info "リストア処理をキャンセルしました。"
                            exit 0
                            ;;
                        a|A)
                            restore_database "$selected_date" "${files[@]}"
                            ;;
                        [0-9]*)
                            if [ "$file_choice" -ge 1 ] && [ "$file_choice" -le ${#files[@]} ]; then
                                local selected_file="${files[$((file_choice-1))]}"
                                restore_database "$selected_date" "$selected_file"
                            else
                                echo_error "無効な選択です: $file_choice"
                                exit 1
                            fi
                            ;;
                        *)
                            echo_error "無効な選択です: $file_choice"
                            exit 1
                            ;;
                    esac
                else
                    echo_error "無効な選択です: $date_choice"
                    exit 1
                fi
                ;;
            *)
                echo_error "無効な選択です: $date_choice"
                exit 1
                ;;
        esac
    fi

    echo ""
    echo_success "✨ データベースリストア処理が完了しました！"
    echo_info "アプリケーション確認: https://www.brighttalk.jp"
}

# スクリプト実行
main "$@"