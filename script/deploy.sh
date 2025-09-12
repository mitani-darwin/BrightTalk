#!/bin/bash

# デプロイスクリプト for BrightTalk
# ECR + Kamal を使用したデプロイ自動化

set -e  # エラー時に停止

# 色付きログ出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 設定値
ECR_REGISTRY="017820660529.dkr.ecr.ap-northeast-1.amazonaws.com"
ECR_REPOSITORY="bright_talk"
AWS_REGION="ap-northeast-1"
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

# ECRログイン
ecr_login() {
    echo_info "ECRにログイン中..."

    if aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY; then
        echo_success "ECRログイン成功"
    else
        echo_error "ECRログインに失敗しました"
        exit 1
    fi
}

# 環境変数の設定
setup_environment() {
    echo_info "環境変数を設定中..."

    # ECRパスワードの取得と設定
    export ECR_PASSWORD=$(aws ecr get-login-password --region $AWS_REGION)

    if [ -z "$ECR_PASSWORD" ]; then
        echo_error "ECRパスワードの取得に失敗しました"
        exit 1
    fi

    # 必要な環境変数のチェック
    if [ -z "$SSH_KEY_PATH" ]; then
        echo_warning "SSH_KEY_PATHが設定されていません。~/.ssh/id_rsaを使用します。"
        export SSH_KEY_PATH="~/.ssh/id_rsa"
    fi

    echo_success "環境変数の設定完了"
    echo_info "ECRパスワード: 設定済み（12時間有効）"
    echo_info "SSH_KEY_PATH: $SSH_KEY_PATH"
}

# Dockerイメージのビルドとプッシュ
build_and_push() {
    local full_image_name="$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"

    echo_info "Dockerイメージをビルド中: $full_image_name"

    if docker build -t $ECR_REPOSITORY:$IMAGE_TAG .; then
        echo_success "Dockerイメージのビルド完了"
    else
        echo_error "Dockerイメージのビルドに失敗しました"
        exit 1
    fi

    echo_info "イメージにタグを付与中..."
    docker tag $ECR_REPOSITORY:$IMAGE_TAG $full_image_name

    echo_info "ECRにプッシュ中: $full_image_name"
    if docker push $full_image_name; then
        echo_success "ECRへのプッシュ完了"
    else
        echo_error "ECRへのプッシュに失敗しました"
        exit 1
    fi
}

# データベースバックアップ
backup_database() {
    echo_info "データベースバックアップを開始..."
    
    local timestamp=$(date +"%Y%m%d_%H%M_%S")
    local s3_bucket="brighttalk-db-backup"
    
    echo_info "SQLite3 .backupコマンドを使用してデータベースバックアップを作成中..."
    
    # データベースファイルのリスト（Rails storage/ディレクトリ内のパス）
    local databases=("production.sqlite3" "production_cache.sqlite3" "production_queue.sqlite3" "production_cable.sqlite3")
    local uploaded_files=()
    
    for db_file in "${databases[@]}"; do
        local source_db="storage/$db_file"
        local backup_filename="${db_file%.sqlite3}_backup_${timestamp}.sqlite3"
        
        echo_info "$db_file のバックアップを作成中..."
        
        # Kamalを使ってDockerコンテナ内でsqlite3 .backupコマンドを実行
        if kamal app exec --reuse "test -f $source_db && sqlite3 $source_db '.backup /tmp/$backup_filename' && echo 'Backup created successfully'" 2>/dev/null | grep -q "Backup created successfully"; then
            # Base64エンコードでバイナリファイルを安全に転送
            if kamal app exec --reuse "base64 /tmp/$backup_filename" > "/tmp/b64_$backup_filename" 2>/dev/null && \
               [ -s "/tmp/b64_$backup_filename" ] && \
               base64 -d "/tmp/b64_$backup_filename" > "$backup_filename" 2>/dev/null && \
               [ -s "$backup_filename" ]; then
                
                # 一時ファイルをクリーンアップ
                rm -f "/tmp/b64_$backup_filename"
                kamal app exec --reuse "rm -f /tmp/$backup_filename" 2>/dev/null
                
                # S3に個別ファイルをアップロード
                echo_info "S3にバックアップをアップロード中: s3://$s3_bucket/$backup_filename"
                
                if aws s3 cp "$backup_filename" "s3://$s3_bucket/" --region $AWS_REGION; then
                    echo_success "$db_file のS3アップロード完了"
                    uploaded_files+=("$backup_filename")
                    
                    # ローカルファイルを削除
                    rm -f "$backup_filename"
                else
                    echo_warning "$db_file のS3アップロードに失敗しました"
                    rm -f "$backup_filename"
                fi
            else
                echo_warning "$db_file のバックアップダウンロードに失敗しました"
                rm -f "$backup_filename"
            fi
        else
            echo_warning "$db_file が見つからないか、バックアップの作成に失敗しました"
        fi
    done
    
    if [ ${#uploaded_files[@]} -gt 0 ]; then
        echo_success "データベースバックアップ完了: ${#uploaded_files[@]}個のファイルをS3にアップロード"
        for file in "${uploaded_files[@]}"; do
            echo_info "  - s3://$s3_bucket/$file"
        done
    else
        echo_error "バックアップファイルのアップロードに失敗しました"
        exit 1
    fi
}

# Kamalデプロイ
kamal_deploy() {
    echo_info "Kamalでデプロイを開始..."

    if kamal deploy; then
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
    echo_info "ECRリポジトリ: $ECR_REGISTRY/$ECR_REPOSITORY"
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
                echo "  --skip-push     ECRプッシュをスキップ"
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
    ecr_login
    setup_environment

    if [ "$SKIP_BUILD" = false ]; then
        build_and_push
    elif [ "$SKIP_PUSH" = false ]; then
        echo_info "ビルドをスキップして、プッシュを実行..."
        local full_image_name="$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
        docker tag $ECR_REPOSITORY:$IMAGE_TAG $full_image_name
        docker push $full_image_name
    else
        echo_info "ビルドとプッシュをスキップします"
    fi

    # デプロイ前にデータベースをバックアップ
    backup_database

    kamal_deploy

    echo ""
    echo_success "✨ すべての処理が完了しました！"
    echo_info "アプリケーションURL: https://www.brighttalk.jp"
    echo_info "ログ確認: kamal app logs -f"
}

# スクリプト実行
main "$@"