#!/usr/bin/env node
/**
 * CodeEditor機能のCIテスト
 * Node.js環境でCodeMirrorとStimulusコントローラーの動作を検証
 */

const fs = require('fs');
const path = require('path');

console.log('=== CodeEditor CI テスト開始 ===\n');

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
        'app/javascript/controllers/code_editor_controller.js',
        'app/views/posts/_form_main_content.html.erb',
        'package.json'
    ];
    
    requiredFiles.forEach(filePath => {
        const fullPath = path.join(__dirname, filePath);
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
        const packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8'));
        
        const requiredDependencies = [
            '@hotwired/stimulus',
            'codemirror'
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
        const appJsContent = fs.readFileSync(path.join(__dirname, 'app/javascript/application.js'), 'utf8');
        
        // 必要なimport文の確認
        const requiredImports = [
            'import CodeMirror from \'codemirror\'',
            'import { Application } from "@hotwired/stimulus"',
            'import CodeEditorController from "./controllers/code_editor_controller"'
        ];
        
        requiredImports.forEach(importStatement => {
            const exists = appJsContent.includes(importStatement.replace(/'/g, '"')) || appJsContent.includes(importStatement);
            addTestResult(`Import確認: ${importStatement}`, exists);
        });
        
        // CodeMirrorの初期化確認
        const hasCodeMirrorInit = appJsContent.includes('window.CodeMirror = CodeMirror') ||
                                 appJsContent.includes('loadCodeMirror');
        addTestResult('CodeMirror初期化設定', hasCodeMirrorInit);
        
        // Stimulusコントローラー登録確認
        const hasControllerRegistration = appJsContent.includes('register("code-editor", CodeEditorController)');
        addTestResult('Stimulusコントローラー登録', hasControllerRegistration);
        
    } catch (error) {
        addTestResult('application.js解析', false, error.message);
    }
}

/**
 * テスト4: CodeEditorController設定確認
 */
function testCodeEditorController() {
    console.log('\n--- CodeEditorController設定テスト ---');
    
    try {
        const controllerContent = fs.readFileSync(path.join(__dirname, 'app/javascript/controllers/code_editor_controller.js'), 'utf8');
        
        // 必要なメソッドの確認
        const requiredMethods = [
            'connect()',
            'initializeCodeMirror()',
            'insertText(',
            'disconnect()'
        ];
        
        requiredMethods.forEach(method => {
            const exists = controllerContent.includes(method);
            addTestResult(`メソッド確認: ${method}`, exists);
        });
        
        // Stimulusのtarget設定確認
        const hasTextareaTarget = controllerContent.includes('static targets = ["textarea"]');
        addTestResult('Stimulus target設定', hasTextareaTarget);
        
        // CodeMirror初期化ロジック確認
        const hasInitLogic = controllerContent.includes('CodeMirror.fromTextArea') &&
                            controllerContent.includes('mode: \'markdown\'');
        addTestResult('CodeMirror初期化ロジック', hasInitLogic);
        
    } catch (error) {
        addTestResult('CodeEditorController解析', false, error.message);
    }
}

/**
 * テスト5: HTMLビューファイル設定確認
 */
function testHtmlViewConfiguration() {
    console.log('\n--- HTMLビュー設定テスト ---');
    
    try {
        const viewContent = fs.readFileSync(path.join(__dirname, 'app/views/posts/_form_main_content.html.erb'), 'utf8');
        
        // data-controller属性の確認
        const hasDataController = viewContent.includes('controller: "code-editor"') || viewContent.includes('data-controller="code-editor"');
        addTestResult('data-controller属性', hasDataController);
        
        // data-target属性の確認  
        const hasDataTarget = viewContent.includes('code_editor_target: "textarea"') || viewContent.includes('data-code-editor-target="textarea"');
        addTestResult('data-target属性', hasDataTarget);
        
        // textarea要素の確認
        const hasTextarea = viewContent.includes('form.text_area') && viewContent.includes('id: "contentTextarea"');
        addTestResult('textarea要素', hasTextarea);
        
    } catch (error) {
        addTestResult('HTMLビュー解析', false, error.message);
    }
}

/**
 * テスト6: ビルドファイルの確認
 */
function testBuildFiles() {
    console.log('\n--- ビルドファイル確認テスト ---');
    
    const buildFiles = [
        'app/assets/builds/application.js'
    ];
    
    buildFiles.forEach(filePath => {
        const fullPath = path.join(__dirname, filePath);
        const exists = fs.existsSync(fullPath);
        if (exists) {
            const stats = fs.statSync(fullPath);
            const sizeKB = Math.round(stats.size / 1024);
            addTestResult(`ビルドファイル: ${filePath}`, exists, `サイズ: ${sizeKB}KB`);
        } else {
            addTestResult(`ビルドファイル: ${filePath}`, exists, 'ファイルが見つかりません');
        }
    });
}

/**
 * メインテスト実行
 */
async function runTests() {
    testFileExistence();
    testPackageJsonDependencies();
    testApplicationJsConfiguration();
    testCodeEditorController();
    testHtmlViewConfiguration();
    testBuildFiles();
    
    console.log('\n=== テスト結果サマリー ===');
    const passedTests = testResults.filter(result => result.passed).length;
    const totalTests = testResults.length;
    const failedTests = testResults.filter(result => !result.passed);
    
    console.log(`総テスト数: ${totalTests}`);
    console.log(`成功: ${passedTests}`);
    console.log(`失敗: ${totalTests - passedTests}`);
    
    if (failedTests.length > 0) {
        console.log('\n--- 失敗したテスト ---');
        failedTests.forEach(test => {
            console.log(`✗ ${test.testName}: ${test.message}`);
        });
    }
    
    const success = failedTests.length === 0;
    console.log(`\n=== テスト結果: ${success ? '成功' : '失敗'} ===`);
    
    // 終了コード設定（CI環境での利用を想定）
    process.exit(success ? 0 : 1);
}

// テスト実行
runTests().catch(error => {
    console.error('テスト実行中にエラーが発生しました:', error);
    process.exit(1);
});