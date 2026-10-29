'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const root = __dirname;
const sourceFiles = ['Scripts/mobEAD.dataAccess.js', 'Scripts/mobEAD.js'];

// Simulacao minima do Knockout para testar a logica da aplicacao sem navegador.
function loadApp() {
    const context = { console };
    context.window = context;
    const observable = (initial) => {
        let value = initial;
        return function (next) {
            if (arguments.length !== 0) value = next;
            return value;
        };
    };
    context.ko = {
        observable,
        observableArray: (value = []) => observable(value),
        computed: (settings) => settings.read.bind(settings.owner),
        applyBindings: (viewModel) => { context.boundViewModel = viewModel; }
    };
    context.$ = { map: (items, mapping) => items.map(mapping) };
    vm.createContext(context);
    for (const name of sourceFiles) {
        vm.runInContext(fs.readFileSync(path.join(root, name), 'utf8'), context, { filename: name });
    }
    return context.boundViewModel;
}

test('carrega dois simulados com tres perguntas cada', () => {
    const app = loadApp();
    assert.equal(app.Tests().length, 2);
    for (const exam of app.Tests()) assert.equal(exam.Questions().length, 3);
});

test('seleciona uma prova e navega entre perguntas', () => {
    const app = loadApp();
    const exam = app.Tests()[0];
    app.selectTest(exam);
    assert.equal(app.CurrentTest(), exam);
    exam.nextQuestion();
    assert.equal(exam.CurrentQuestion(), 1);
    exam.previousQuestion();
    assert.equal(exam.CurrentQuestion(), 0);
    app.openTestList();
    assert.equal(app.CurrentTest(), null);
});

test('duas respostas corretas atingem a pontuacao minima', () => {
    const exam = loadApp().Tests()[0];
    exam.Questions()[0].selectAlternative(1);
    exam.Questions()[1].selectAlternative(2);
    exam.endTest();
    assert.equal(exam.ActualCorrectAmount(), 2);
    assert.equal(exam.Result(), true);
    assert.equal(exam.ShowResult(), true);
});

test('prova sem respostas reprova', () => {
    const exam = loadApp().Tests()[1];
    exam.endTest();
    assert.equal(exam.ActualCorrectAmount(), 0);
    assert.equal(exam.Result(), false);
});

test('clicar duas vezes desfaz a selecao', () => {
    const question = loadApp().Tests()[0].Questions()[0];
    question.selectAlternative(3);
    assert.equal(question.NumberAnswered(), 3);
    question.selectAlternative(3);
    assert.equal(question.NumberAnswered(), 0);
});

test('HTML referencia arquivos locais existentes', () => {
    const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
    assert.match(html, /MobEAD - UNYLEYA - Engenharia DevOps/);
    const activeHtml = html.replace(/<!--[\s\S]*?-->/g, '');
    const resources = [
        ...activeHtml.matchAll(/<script\s+src="([^"]+)"/g),
        ...activeHtml.matchAll(/<link\s+href="([^"]+)"/g)
    ].map((match) => match[1]);
    assert.ok(resources.length >= 6, 'Scripts e CSS nao encontrados no HTML');
    for (const resource of resources) {
        assert.ok(!resource.startsWith('http') && !resource.startsWith('//'));
        assert.ok(fs.existsSync(path.join(root, resource)), `Arquivo ausente: ${resource}`);
    }
});

test('JavaScript da aplicacao possui sintaxe valida', () => {
    for (const name of [...sourceFiles, 'Scripts/mobEAD.bindings.js']) {
        assert.doesNotThrow(() => new vm.Script(fs.readFileSync(path.join(root, name), 'utf8')));
    }
});
