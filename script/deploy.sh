#!/bin/bash

# デプロイスクリプト for BrightTalk
# Docker Hub + Kamal を使用したデプロイ自動化

set -e  # エラー時に停止

# 色付きログ出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 設定値
REGISTRY="ghcr.io"
# DOCKER_HUB_USERNAME should be set in environment (e.g., .env.production)
REPOSITORY="bright_talk"
AWS_REGION="ap-northeast-1"
IP_ADDRESS="52.192.149.181"
IMAGE_TAG=${1:-latest}

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

    if ! command -v docker &> /dev/null; then
        echo_error "Dockerが見つかりません。インストールしてください。"
        exit 1
    fi

    if ! command -v kamal &> /dev/null; then
        echo_error "Kamalが見つかりません。インストールしてください。"
        exit 1
    fi

    echo_success "前提条件のチェック完了"
}

# GitHub Container Registry ログイン関数を追加
ghcr_login() {
    echo_info "GitHub Container Registry にログイン中..."

    if echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin; then
        echo_success "GitHub Container Registry ログイン成功"
    else
        echo_error "GitHub Container Registry ログインに失敗しました。GITHUB_USERNAME / GITHUB_TOKEN を確認してください。"
        exit 1
    fi
}

# 環境変数の設定
setup_environment() {
    echo_info "環境変数を設定中..."
    . ./.env.production

    echo "GITHUB_USERNAME:" . $GITHUB_USERNAME
    echo "APP_NAME:" . $APP_NAME
    echo "GITHUB_TOKEN" . $GITHUB_TOKEN

    if [ -z "$SSH_KEY_PATH" ]; then
        echo_warning "SSH_KEY_PATHが設定されていません。~/.ssh/id_rsaを使用します。"
        export SSH_KEY_PATH="~/.ssh/id_rsa"
    fi

    echo_success "環境変数の設定完了"
    echo_info "SSH_KEY_PATH: $SSH_KEY_PATH"
}

## Dockerイメージのビルドとプッシュ
build_and_push() {
  echo_info "build_and_pushが呼び出されました"
}

# データベースバックアップ
backup_database() {
    echo_info "データベースバックアップを開始..."
    
    local date_dir=$(date +"%Y-%m-%d")
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local s3_bucket="brighttalk-db-backup"
    
    echo_info "SQLite3 .backupコマンドを使用してデータベースバックアップを作成中..."
    echo_info "バックアップディレクトリ: $date_dir"
    
    # データベースファイルのリスト
    local databases=("production.sqlite3" "production_cache.sqlite3" "production_queue.sqlite3" "production_cable.sqlite3")
    local uploaded_files=()
    
    # 現在動作中のコンテナ名を取得
    local container_name=$(ssh -p 47583 -i $SSH_KEY_PATH ec2-user@$IP_ADDRESS "docker ps --filter label=service=bright_talk --filter label=role=web --format '{{.Names}}' | head -1")
    
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
        ssh -p 47583 -i $SSH_KEY_PATH ec2-user@$IP_ADDRESS "docker exec $container_name sqlite3 $source_db 'PRAGMA wal_checkpoint(FULL);'" 2>/dev/null
        
        # SQLite3 .backupを実行
        if ssh -p 47583 -i $SSH_KEY_PATH ec2-user@$IP_ADDRESS "docker exec $container_name sqlite3 $source_db '.backup /tmp/$backup_filename' && echo 'Backup created successfully'" 2>/dev/null | grep -q "Backup created successfully"; then
            
            echo_info "バックアップ作成成功、圧縮とファイル転送を開始..."
            
            # gzipで圧縮してローカルに転送
            if ssh -p 47583 -i $SSH_KEY_PATH ec2-user@$IP_ADDRESS "docker exec $container_name test -f /tmp/$backup_filename && docker exec $container_name gzip -c /tmp/$backup_filename" > "$compressed_filename" 2>/dev/null; then
                
                # 圧縮ファイルの存在とサイズを確認
                if [ -s "$compressed_filename" ]; then
                    echo_info "圧縮ファイル転送成功 ($(wc -c < "$compressed_filename") bytes)"
                    
                    # コンテナ内の一時ファイルをクリーンアップ
                    ssh -p 47583 -i $SSH_KEY_PATH ec2-user@$IP_ADDRESS "docker exec $container_name rm -f /tmp/$backup_filename" 2>/dev/null
                    
                    # S3に圧縮ファイルをアップロード
                    echo_info "S3に圧縮バックアップをアップロード中: s3://$s3_bucket/$date_dir/$compressed_filename"
                    
                    if aws s3 cp "$compressed_filename" "s3://$s3_bucket/$date_dir/" --region $AWS_REGION; then
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
                    ssh -p 47583 -i $SSH_KEY_PATH ec2-user@$IP_ADDRESS "docker exec $container_name rm -f /tmp/$backup_filename" 2>/dev/null
                fi
            else
                echo_warning "$db_file の圧縮処理に失敗しました"
                ssh -p 47583 -i $SSH_KEY_PATH ec2-user@$IP_ADDRESS "docker exec $container_name rm -f /tmp/$backup_filename" 2>/dev/null
            fi
        else
            echo_warning "$db_file が見つからないか、バックアップの作成に失敗しました"
        fi
    done
    
    if [ ${#uploaded_files[@]} -gt 0 ]; then
        echo_success "データベースバックアップ完了: ${#uploaded_files[@]}個のファイルをS3にアップロード"
        for file in "${uploaded_files[@]}"; do
            echo_info "  - s3://$s3_bucket/$date_dir/$file"
        done
    else
        echo_error "バックアップファイルのアップロードに失敗しました"
        exit 1
    fi
}

# Kamalデプロイ
kamal_deploy() {
    echo_info "Kamalでデプロイを開始..."

    if dotenv -f .env.production kamal deploy; then
        echo_success "🎉 デプロイが正常に完了しました！"
    else
        echo_error "Kamalデプロイに失敗しました"
        exit 1
    fi
}

# メイン処理
main() {
    echo_info "🚀 BrightTalk デプロイスクリプト開始"
    echo_info "イメージタグ: $IMAGE_TAG"
    echo_info "Docker Hub リポジトリ: $REGISTRY/$REPOSITORY"
    echo ""

    # 引数の処理
    SKIP_BUILD=false
    SKIP_PUSH=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-push)
                SKIP_PUSH=true
                shift
                ;;
            --deploy-only)
                SKIP_BUILD=true
                SKIP_PUSH=true
                shift
                ;;
            -h|--help)
                echo "使用方法: $0 [IMAGE_TAG] [OPTIONS]"
                echo ""
                echo "OPTIONS:"
                echo "  --skip-build    Dockerビルドをスキップ"
                echo "  --skip-push     Docker Hubプッシュをスキップ"
                echo "  --deploy-only   ビルドとプッシュをスキップ、デプロイのみ実行"
                echo "  -h, --help      このヘルプを表示"
                echo ""
                echo "例:"
                echo "  $0                    # 最新版をビルド・プッシュ・デプロイ"
                echo "  $0 v1.0.0             # v1.0.0タグでビルド・プッシュ・デプロイ"
                echo "  $0 --deploy-only      # デプロイのみ実行"
                echo "  $0 --skip-build       # ビルドをスキップしてプッシュ・デプロイ"
                exit 0
                ;;
            *)
                IMAGE_TAG="$1"
                shift
                ;;
        esac
    done

    # 処理実行
    check_prerequisites
    setup_environment
    ghcr_login

    if [ "$SKIP_BUILD" = false ]; then
        build_and_push
    elif [ "$SKIP_PUSH" = false ]; then
        echo_info "ビルドをスキップして、プッシュを実行..."
        local full_image_name="$REGISTRY/$REPOSITORY:$IMAGE_TAG"
        docker tag $REPOSITORY:$IMAGE_TAG $full_image_name
        docker push $full_image_name
    else
        echo_info "ビルドとプッシュをスキップします"
    fi

    # デプロイ前にデータベースをバックアップ
    # backup_database

    # docker build --no-cache -t brighttalk .
    pwd
    dotenv -f .env.production kamal deploy

    echo ""
    echo_success "✨ すべての処理が完了しました！"
    echo_info "アプリケーションURL: https://www.brighttalk.jp"
    echo_info "ログ確認: kamal app logs -f"
}

# スクリプト実行
main "$@"