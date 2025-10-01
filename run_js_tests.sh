#!/bin/bash

# JavaScript テスト実行スクリプト
# Usage: ./run_js_tests.sh [option]
# Options:
#   all - 全てのJavaScriptテストを実行 (デフォルト)
#   application - Application.jsのテストのみ実行
#   passkey - Passkey.jsのテストのみ実行
#   codeeditor-controller - CodeEditorControllerのテストのみ実行
#   videoplayer-controller - VideoPlayerControllerのテストのみ実行
#   flatpickr-controller - FlatpickrControllerのテストのみ実行
#   codeeditor - CodeEditorのテストのみ実行
#   codeeditor-markdown - CodeEditorMarkdownのテストのみ実行
#   videoplayer - VideoPlayerのテストのみ実行
#   help - このヘルプを表示

set -e  # エラー時にスクリプトを停止

# 色付きの出力用関数
print_green() {
    echo -e "\033[32m$1\033[0m"
}

print_red() {
    echo -e "\033[31m$1\033[0m"
}

print_yellow() {
    echo -e "\033[33m$1\033[0m"
}

print_blue() {
    echo -e "\033[34m$1\033[0m"
}

# ヘルプ表示
show_help() {
    echo "JavaScript テスト実行スクリプト"
    echo ""
    echo "使用方法: ./run_js_tests.sh [option]"
    echo ""
    echo "オプション:"
    echo "  all                     - 全てのJavaScriptテストを実行 (デフォルト)"
    echo "  application             - Application.jsのテストのみ実行"
    echo "  passkey                 - Passkey.jsのテストのみ実行"
    echo "  codeeditor-controller   - CodeEditorControllerのテストのみ実行"
    echo "  videoplayer-controller  - VideoPlayerControllerのテストのみ実行"
    echo "  flatpickr-controller    - FlatpickrControllerのテストのみ実行"
    echo "  codeeditor              - CodeEditorのテストのみ実行"
    echo "  codeeditor-markdown     - CodeEditorMarkdownのテストのみ実行"
    echo "  videoplayer             - VideoPlayerのテストのみ実行"
    echo "  help                    - このヘルプを表示"
    echo ""
}

# テスト実行前の準備
prepare_tests() {
    print_blue "=========================================="
    print_blue "    JavaScript テスト実行開始"
    print_blue "=========================================="
    
    # Node.jsとnpmの確認
    if ! command -v node &> /dev/null; then
        print_red "エラー: Node.jsがインストールされていません"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        print_red "エラー: npmがインストールされていません"
        exit 1
    fi
    
    print_green "✓ Node.js: $(node --version)"
    print_green "✓ npm: $(npm --version)"
    echo ""
}

# 個別テスト実行関数
run_single_test() {
    local test_name=$1
    local npm_script=$2
    
    print_yellow "----------------------------------------"
    print_yellow "  ${test_name} テスト実行中..."
    print_yellow "----------------------------------------"
    
    if npm run "$npm_script"; then
        print_green "✓ ${test_name} テスト: 成功"
    else
        print_red "✗ ${test_name} テスト: 失敗"
        return 1
    fi
    echo ""
}

# 全テスト実行
run_all_tests() {
    print_yellow "----------------------------------------"
    print_yellow "  全てのJavaScriptテスト実行中..."
    print_yellow "----------------------------------------"
    
    local failed_tests=()
    local success_count=0
    local total_count=8
    
    # 各テストを個別に実行して結果を記録
    tests=(
        "Application.js:test:application"
        "Passkey.js:test:passkey"
        "CodeEditorController:test:codeeditor-controller"
        "VideoPlayerController:test:videoplayer-controller"
        "FlatpickrController:test:flatpickr-controller"
        "CodeEditor:test:codeeditor"
        "CodeEditorMarkdown:test:codeeditor-markdown"
        "VideoPlayer:test:videoplayer"
    )
    
    for test_info in "${tests[@]}"; do
        IFS=':' read -r test_name npm_script <<< "$test_info"
        if run_single_test "$test_name" "$npm_script"; then
            ((success_count++))
        else
            failed_tests+=("$test_name")
        fi
    done
    
    # 結果サマリー
    print_blue "=========================================="
    print_blue "    テスト実行結果"
    print_blue "=========================================="
    print_green "成功: $success_count/$total_count テスト"
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        print_red "失敗したテスト:"
        for failed_test in "${failed_tests[@]}"; do
            print_red "  - $failed_test"
        done
        return 1
    else
        print_green "✓ 全てのテストが成功しました！"
    fi
}

# メイン処理
main() {
    local option=${1:-all}
    
    case "$option" in
        help)
            show_help
            exit 0
            ;;
        all)
            prepare_tests
            run_all_tests
            ;;
        application)
            prepare_tests
            run_single_test "Application.js" "test:application"
            ;;
        passkey)
            prepare_tests
            run_single_test "Passkey.js" "test:passkey"
            ;;
        codeeditor-controller)
            prepare_tests
            run_single_test "CodeEditorController" "test:codeeditor-controller"
            ;;
        videoplayer-controller)
            prepare_tests
            run_single_test "VideoPlayerController" "test:videoplayer-controller"
            ;;
        flatpickr-controller)
            prepare_tests
            run_single_test "FlatpickrController" "test:flatpickr-controller"
            ;;
        codeeditor)
            prepare_tests
            run_single_test "CodeEditor" "test:codeeditor"
            ;;
        codeeditor-markdown)
            prepare_tests
            run_single_test "CodeEditorMarkdown" "test:codeeditor-markdown"
            ;;
        videoplayer)
            prepare_tests
            run_single_test "VideoPlayer" "test:videoplayer"
            ;;
        *)
            print_red "エラー: 不明なオプション '$option'"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"