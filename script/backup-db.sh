#!/bin/bash

# データベースバックアップ専用スクリプト for BrightTalk
# SQLite3データベースをS3にバックアップ

set -e  # エラー時に停止

# 色付きログ出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# データベースバックアップ
backup_database() {
    echo_info "データベースバックアップを開始..."
    
    local date_dir=$(date +"%Y-%m-%d")
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    echo_info "SQLite3 .backupコマンドを使用してデータベースバックアップを作成中..."
    echo_info "バックアップディレクトリ: $date_dir"
    
    # データベースファイルのリスト
    local databases=("production.sqlite3" "production_cache.sqlite3" "production_queue.sqlite3" "production_cable.sqlite3")
    local uploaded_files=()
    
    # 現在動作中のコンテナ名を取得
    local container_name=$(ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker ps --filter label=service=bright_talk --filter label=role=web --format '{{.Names}}' | head -1")
    
    if [ -z "$container_name" ]; then
        echo_error "コンテナが見つかりません"
        exit 1
    fi
    
    echo_info "使用するコンテナ: $container_name"
    
    for db_file in "${databases[@]}"; do
        local source_db="/rails/storage/$db_file"
        local backup_filename="${db_file%.sqlite3}_backup_${timestamp}.sqlite3"
        local compressed_filename="${backup_filename}.gz"
        
        echo_info "$db_file のバックアップを作成中..."
        
        # WALチェックポイントを実行（SQLiteのWALモード対応）
        ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name sqlite3 $source_db 'PRAGMA wal_checkpoint(FULL);'" 2>/dev/null
        
        # SQLite3 .backupを実行
        if ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name sqlite3 $source_db '.backup /tmp/$backup_filename' && echo 'Backup created successfully'" 2>/dev/null | grep -q "Backup created successfully"; then
            
            echo_info "バックアップ作成成功、圧縮とファイル転送を開始..."
            
            # gzipで圧縮してローカルに転送
            if ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name test -f /tmp/$backup_filename && docker exec $container_name gzip -c /tmp/$backup_filename" > "$compressed_filename" 2>/dev/null; then
                
                # 圧縮ファイルの存在とサイズを確認
                if [ -s "$compressed_filename" ]; then
                    echo_info "圧縮ファイル転送成功 ($(wc -c < "$compressed_filename") bytes)"
                    
                    # コンテナ内の一時ファイルをクリーンアップ
                    ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name rm -f /tmp/$backup_filename" 2>/dev/null
                    
                    # S3に圧縮ファイルをアップロード
                    echo_info "S3に圧縮バックアップをアップロード中: s3://$S3_BUCKET/$date_dir/$compressed_filename"
                    
                    if aws s3 cp "$compressed_filename" "s3://$S3_BUCKET/$date_dir/" --region $AWS_REGION; then
                        echo_success "$db_file のS3アップロード完了"
                        uploaded_files+=("$compressed_filename")
                        rm -f "$compressed_filename"
                    else
                        echo_warning "$db_file のS3アップロードに失敗しました"
                        rm -f "$compressed_filename"
                    fi
                else
                    echo_warning "$db_file の圧縮ファイル転送に失敗しました（ファイルが空またはエラー）"
                    rm -f "$compressed_filename"
                    ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name rm -f /tmp/$backup_filename" 2>/dev/null
                fi
            else
                echo_warning "$db_file の圧縮処理に失敗しました"
                ssh -p 47583 -i $SSH_KEY_PATH ec2-user@57.182.140.42 "docker exec $container_name rm -f /tmp/$backup_filename" 2>/dev/null
            fi
        else
            echo_warning "$db_file が見つからないか、バックアップの作成に失敗しました"
        fi
    done
    
    if [ ${#uploaded_files[@]} -gt 0 ]; then
        echo_success "データベースバックアップ完了: ${#uploaded_files[@]}個のファイルをS3にアップロード"
        for file in "${uploaded_files[@]}"; do
            echo_info "  - s3://$S3_BUCKET/$date_dir/$file"
        done
    else
        echo_error "バックアップファイルのアップロードに失敗しました"
        exit 1
    fi
}

# ヘルプ表示
show_help() {
    echo "使用方法: $0 [OPTIONS]"
    echo ""
    echo "BrightTalkのSQLite3データベースをS3にバックアップします"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help      このヘルプを表示"
    echo ""
    echo "環境変数:"
    echo "  SSH_KEY_PATH    SSH秘密鍵のパス (デフォルト: terraform/ssh-keys/mac-mini-2023.local-ed25519-key)"
    echo ""
    echo "例:"
    echo "  $0                           # データベースバックアップを実行"
    echo "  SSH_KEY_PATH=~/.ssh/id_rsa $0  # カスタムSSH鍵を使用"
}

# メイン処理
main() {
    echo_info "🗄️  BrightTalk データベースバックアップスクリプト開始"
    echo_info "S3バケット: $S3_BUCKET"
    echo_info "リージョン: $AWS_REGION"
    echo ""

    # 引数の処理
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo_error "不明なオプション: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 処理実行
    check_prerequisites
    backup_database

    echo ""
    echo_success "✨ データベースバックアップが完了しました！"
    echo_info "S3バケット: s3://$S3_BUCKET/"
}

# スクリプト実行
main "$@"