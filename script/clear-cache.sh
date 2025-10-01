#!/bin/bash
set -e

# 色付きログ出力
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 設定値
IP_ADDRESS="52.192.149.181"
SSH_KEY_PATH=${SSH_KEY_PATH:-"~/.ssh/id_rsa"}

clear_rails_cache() {
    echo_info "Railsアプリケーションキャッシュをクリア中..."

    # 実行中のコンテナでキャッシュクリア
    kamal app exec --reuse "bin/rails cache:clear"
    echo_success "Railsキャッシュクリア完了"
}

clear_solid_cache() {
    echo_info "Solid Cacheをクリア中..."

    # Solid Cacheの完全クリア
    kamal app exec --reuse "bin/rails runner 'Rails.cache.clear'"
    echo_success "Solid Cacheクリア完了"
}

precompile_assets() {
    echo_info "アセットを再コンパイル中..."

    kamal app exec --reuse "bin/rails assets:precompile"
    echo_success "アセット再コンパイル完了"
}

clear_cloudfront_cache() {
    echo_info "CloudFrontキャッシュをクリア中..."

    # CloudFrontディストリビューションID取得
    local distribution_id=$(aws cloudfront list-distributions \
        --query "DistributionList.Items[?Comment=='CloudFront distribution for brighttalk production video content'].Id" \
        --output text 2>/dev/null)

    if [ -n "$distribution_id" ] && [ "$distribution_id" != "None" ]; then
        echo_info "CloudFront Distribution ID: $distribution_id"

        # インバリデーション実行
        local invalidation_id=$(aws cloudfront create-invalidation \
            --distribution-id "$distribution_id" \
            --paths "/*" \
            --query "Invalidation.Id" \
            --output text)

        if [ -n "$invalidation_id" ]; then
            echo_success "CloudFrontインバリデーション開始: $invalidation_id"
            echo_info "インバリデーション完了まで数分かかる場合があります"
        else
            echo_warning "CloudFrontインバリデーションの開始に失敗しました"
        fi
    else
        echo_warning "CloudFrontディストリビューションが見つかりません"
    fi
}

restart_application() {
    echo_info "アプリケーションを再起動中..."

    # Kamalでアプリケーション再起動
    kamal app boot
    echo_success "アプリケーション再起動完了"
}

# メイン処理
main() {
    echo_info "🧹 BrightTalk キャッシュクリアスクリプト開始"
    echo ""

    # 各キャッシュを順番にクリア
    clear_rails_cache
    clear_solid_cache
    precompile_assets
    clear_cloudfront_cache

    # オプション: アプリケーション再起動
    read -p "アプリケーションを再起動しますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restart_application
    fi

    echo ""
    echo_success "✨ キャッシュクリア処理が完了しました！"
}

# スクリプト実行
main "$@"