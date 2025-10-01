#!/usr/bin/env node
/**
 * VideoPlayer機能のCIテスト
 * Node.js環境でVideo.jsとStimulusコントローラーの動作を検証
 */

const fs = require('fs');
const path = require('path');

console.log('=== VideoPlayer CI テスト開始 ===\n');

// テスト結果を記録する配列
const testResults = [];

/**
 * テスト結果を記録する関数
 */
function addTestResult(testName, passed, message = '') {
    const status = passed ? '✓' : '✗';
    const result = { testName, passed, message, status };
    testResults.push(result);
    console.log(`${status} ${testName}${message ? ': ' + message : ''}`);
}

/**
 * テスト1: 必要なファイルの存在確認
 */
function testFileExistence() {
    console.log('--- ファイル存在確認テスト ---');
    
    const requiredFiles = [
        'app/javascript/application.js',
        'app/javascript/controllers/video_player_controller.js',
        'package.json'
    ];
    
    requiredFiles.forEach(filePath => {
        const fullPath = path.join(__dirname, '..', filePath);
        const exists = fs.existsSync(fullPath);
        addTestResult(`ファイル存在: ${filePath}`, exists, exists ? '存在' : '見つかりません');
    });
}

/**
 * テスト2: package.jsonの依存関係確認
 */
function testPackageJsonDependencies() {
    console.log('\n--- package.json依存関係テスト ---');
    
    try {
        const packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'package.json'), 'utf8'));
        
        const requiredDependencies = [
            '@hotwired/stimulus',
            'video.js'
        ];
        
        requiredDependencies.forEach(dep => {
            const exists = packageJson.dependencies && packageJson.dependencies[dep];
            addTestResult(`依存関係: ${dep}`, !!exists, exists ? `バージョン: ${exists}` : '見つかりません');
        });
        
    } catch (error) {
        addTestResult('package.json解析', false, error.message);
    }
}

/**
 * テスト3: application.jsの設定確認
 */
function testApplicationJsConfiguration() {
    console.log('\n--- application.js設定テスト ---');
    
    try {
        const appJsContent = fs.readFileSync(path.join(__dirname, '..', 'app/javascript/application.js'), 'utf8');
        
        // 必要なimport文の確認
        const requiredImports = [
            'import { Application } from "@hotwired/stimulus"',
            'import VideoPlayerController from "./controllers/video_player_controller"'
        ];
        
        requiredImports.forEach(importStatement => {
            const exists = appJsContent.includes(importStatement.replace(/'/g, '"')) || appJsContent.includes(importStatement);
            addTestResult(`Import確認: ${importStatement}`, exists);
        });
        
        // Stimulusコントローラー登録確認
        const hasControllerRegistration = appJsContent.includes('register("video-player", VideoPlayerController)');
        addTestResult('Stimulusコントローラー登録', hasControllerRegistration);
        
    } catch (error) {
        addTestResult('application.js解析', false, error.message);
    }
}

/**
 * テスト4: VideoPlayerController設定確認
 */
function testVideoPlayerController() {
    console.log('\n--- VideoPlayerController設定テスト ---');
    
    try {
        const controllerContent = fs.readFileSync(path.join(__dirname, '..', 'app/javascript/controllers/video_player_controller.js'), 'utf8');
        
        // 必要なimport文の確認
        const requiredImports = [
            'import { Controller } from "@hotwired/stimulus"',
            'import videojs from \'video.js\''
        ];
        
        requiredImports.forEach(importStatement => {
            const exists = controllerContent.includes(importStatement.replace(/'/g, '"')) || controllerContent.includes(importStatement);
            addTestResult(`Controller Import: ${importStatement}`, exists);
        });
        
        // クラス定義の確認
        const hasControllerClass = controllerContent.includes('export default class extends Controller');
        addTestResult('Controller クラス定義', hasControllerClass);
        
        // 必要なメソッドの確認
        const requiredMethods = [
            'connect()',
            'disconnect()',
            'initializePlayer()',
            'setupPlayer('
        ];
        
        requiredMethods.forEach(method => {
            const exists = controllerContent.includes(method);
            addTestResult(`メソッド存在: ${method}`, exists);
        });
        
        // targets定義の確認
        const hasTargets = controllerContent.includes('static targets = ["video"]');
        addTestResult('Stimulus targets定義', hasTargets);
        
        // Video.jsの初期化ロジック確認
        const hasVideoJsInit = controllerContent.includes('videojs(');
        addTestResult('Video.js初期化ロジック', hasVideoJsInit);
        
        // エラーハンドリング確認
        const hasErrorHandling = controllerContent.includes('try {') && controllerContent.includes('catch');
        addTestResult('エラーハンドリング', hasErrorHandling);
        
        // プレーヤー破棄処理確認
        const hasPlayerDispose = controllerContent.includes('player.dispose()');
        addTestResult('プレーヤー破棄処理', hasPlayerDispose);
        
    } catch (error) {
        addTestResult('VideoPlayerController解析', false, error.message);
    }
}

/**
 * テスト5: Video.js設定オプション確認
 */
function testVideoJsConfiguration() {
    console.log('\n--- Video.js設定オプション確認テスト ---');
    
    try {
        const controllerContent = fs.readFileSync(path.join(__dirname, '..', 'app/javascript/controllers/video_player_controller.js'), 'utf8');
        
        // 必要な設定オプションの確認
        const requiredOptions = [
            'fluid: true',
            'responsive: true',
            'controls: true',
            'playbackRates:',
            'language:'
        ];
        
        requiredOptions.forEach(option => {
            const exists = controllerContent.includes(option);
            addTestResult(`Video.js オプション: ${option}`, exists);
        });
        
    } catch (error) {
        addTestResult('Video.js設定解析', false, error.message);
    }
}

/**
 * テスト6: DOM操作とイベントハンドリング確認
 */
function testDOMHandling() {
    console.log('\n--- DOM操作とイベントハンドリング確認テスト ---');
    
    try {
        const controllerContent = fs.readFileSync(path.join(__dirname, '..', 'app/javascript/controllers/video_player_controller.js'), 'utf8');
        
        // DOM要素の取得確認
        const hasDOMQuery = controllerContent.includes('querySelector') || controllerContent.includes('videoTarget');
        addTestResult('DOM要素取得', hasDOMQuery);
        
        // 要素存在チェック確認
        const hasElementCheck = controllerContent.includes('if (!videoElement)') || controllerContent.includes('if (!');
        addTestResult('要素存在チェック', hasElementCheck);
        
        // DOMContentLoadedイベント確認
        const hasDOMContentLoaded = controllerContent.includes('DOMContentLoaded');
        addTestResult('DOMContentLoadedイベント処理', hasDOMContentLoaded);
        
        // クラス操作確認
        const hasClassManipulation = controllerContent.includes('classList.add') || controllerContent.includes('classList.contains');
        addTestResult('CSSクラス操作', hasClassManipulation);
        
    } catch (error) {
        addTestResult('DOM操作解析', false, error.message);
    }
}

/**
 * 全テストの実行
 */
function runAllTests() {
    testFileExistence();
    testPackageJsonDependencies();
    testApplicationJsConfiguration();
    testVideoPlayerController();
    testVideoJsConfiguration();
    testDOMHandling();
    
    // テスト結果の集計
    console.log('\n=== テスト結果集計 ===');
    const totalTests = testResults.length;
    const passedTests = testResults.filter(result => result.passed).length;
    const failedTests = totalTests - passedTests;
    
    console.log(`総テスト数: ${totalTests}`);
    console.log(`成功: ${passedTests}`);
    console.log(`失敗: ${failedTests}`);
    console.log(`成功率: ${((passedTests / totalTests) * 100).toFixed(1)}%`);
    
    if (failedTests > 0) {
        console.log('\n=== 失敗したテスト ===');
        testResults.filter(result => !result.passed).forEach(result => {
            console.log(`✗ ${result.testName}: ${result.message}`);
        });
    }
    
    console.log('\n=== VideoPlayer CI テスト完了 ===');
    
    // 終了コード設定（失敗があればエラーで終了）
    process.exit(failedTests > 0 ? 1 : 0);
}

// メイン実行
if (require.main === module) {
    runAllTests();
}

module.exports = {
    runAllTests,
    testResults
};