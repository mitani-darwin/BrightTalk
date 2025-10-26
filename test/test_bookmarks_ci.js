#!/usr/bin/env node
/**
 * Bookmarks機能のCI用テスト
 * Node.js上で必要なファイルや設定の存在を確認する
 */

const fs = require('fs');
const path = require('path');

console.log('=== Bookmarks CI テスト開始 ===\n');

const testResults = [];

function addResult(name, passed, message = '') {
  const status = passed ? '✓' : '✗';
  const detail = message ? `: ${message}` : '';
  testResults.push({ name, passed, message });
  console.log(`${status} ${name}${detail}`);
}

function readFile(relativePath) {
  const fullPath = path.join(__dirname, '..', relativePath);
  if (!fs.existsSync(fullPath)) {
    throw new Error(`${relativePath} が見つかりません`);
  }
  return fs.readFileSync(fullPath, 'utf8');
}

function testFileExistence() {
  console.log('--- ファイル存在確認 ---');
  [
    'app/controllers/bookmarks_controller.rb',
    'app/models/bookmark.rb',
    'app/views/bookmarks/_bookmark_button.html.erb',
    'app/views/bookmarks/index.html.erb',
    'app/views/shared/_navigation.html.erb',
    'config/routes/posts.rb',
    'config/routes/bookmarks.rb',
    'config/routes.rb'
  ].forEach(file => {
    const exists = fs.existsSync(path.join(__dirname, '..', file));
    addResult(`ファイル存在: ${file}`, exists, exists ? '存在' : '未検出');
  });
}

function testControllerContents() {
  console.log('\n--- コントローラー内容確認 ---');
  try {
    const controller = readFile('app/controllers/bookmarks_controller.rb');
    addResult('BookmarsController クラス定義', /class\s+BookmarksController\s+<\s+ApplicationController/.test(controller));
    addResult('authenticate_user! フィルター', controller.includes('before_action :authenticate_user!'));
    addResult('index アクション存在', controller.includes('def index'));
    addResult('create アクション存在', controller.includes('def create'));
    addResult('destroy アクション存在', controller.includes('def destroy'));
    addResult('friendly find を使用', controller.includes('Post.friendly.find('));
  } catch (error) {
    addResult('コントローラー読込', false, error.message);
  }
}

function testModelContents() {
  console.log('\n--- モデル内容確認 ---');
  try {
    const model = readFile('app/models/bookmark.rb');
    addResult('belongs_to user', /belongs_to :user/.test(model));
    addResult('belongs_to post', /belongs_to :post/.test(model));
    addResult('一意制約バリデーション', /validates :user_id, uniqueness: { scope: :post_id/.test(model));
  } catch (error) {
    addResult('モデル読込', false, error.message);
  }
}

function testPartialContents() {
  console.log('\n--- ビュー部分テンプレート確認 ---');
  try {
    const partial = readFile('app/views/bookmarks/_bookmark_button.html.erb');
    addResult('turbo_frame_tag 利用', partial.includes('turbo_frame_tag "bookmark_button_'));
    addResult('リンク メソッド切替', partial.includes("turbo_method: link_method"));
    addResult('style 引数に対応', partial.includes('local_assigns.fetch(:style'));
  } catch (error) {
    addResult('部分テンプレート読込', false, error.message);
  }
}

function testBookmarksIndexView() {
  console.log('\n--- ブックマーク一覧ビュー確認 ---');
  try {
    const indexView = readFile('app/views/bookmarks/index.html.erb');
    addResult('ページタイトル', indexView.includes('ブックマーク一覧'));
    addResult('posts-index クラス適用', indexView.includes('posts-index'));
    addResult('投稿リンク', indexView.includes('link_to post.title'));
  } catch (error) {
    addResult('一覧ビュー読込', false, error.message);
  }
}

function testRoutes() {
  console.log('\n--- ルーティング確認 ---');
  try {
    const routesMain = readFile('config/routes.rb');
    const routesPosts = readFile('config/routes/posts.rb');
    const routesBookmarks = readFile('config/routes/bookmarks.rb');

    addResult('config/routes.rb に draw(:bookmarks)', routesMain.includes('draw(:bookmarks)'));
    addResult('postsルートにブックマークネスト', routesPosts.includes('resources :bookmarks, only: [ :create, :destroy ]'));
    addResult('bookmarksルートにindex', /resources :bookmarks, only: \[:index\]/.test(routesBookmarks));
  } catch (error) {
    addResult('ルーティング読込', false, error.message);
  }
}

function testNavigationLink() {
  console.log('\n--- ナビゲーション表示確認 ---');
  try {
    const navView = readFile('app/views/shared/_navigation.html.erb');
    const hasLink = navView.includes('ブックマーク一覧');
    addResult('ナビゲーションにブックマークリンク', hasLink);
  } catch (error) {
    addResult('ナビゲーション読込', false, error.message);
  }
}

function finalize() {
  console.log('\n=== Bookmarks CI テスト結果 ===');
  const passed = testResults.filter(r => r.passed).length;
  const failed = testResults.length - passed;
  console.log(`合計: ${testResults.length}件 / 成功: ${passed}件 / 失敗: ${failed}件`);
  if (failed > 0) {
    process.exitCode = 1;
  }
}

// テスト実行
testFileExistence();
testControllerContents();
testModelContents();
testPartialContents();
testBookmarksIndexView();
testRoutes();
testNavigationLink();
finalize();
