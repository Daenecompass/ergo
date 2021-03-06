/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

const Ergo = require('../lib/ergo');
const Chai = require('chai');

Chai.should();
Chai.use(require('chai-things'));

const Fs = require('fs');
const Path = require('path');

describe('ergo-compiler', () => {

    afterEach(() => {});

    describe('#callname', function () {
        it('should sanitize call names for contracts', async function () {
            const contractName = 'org.accordproject.volumediscount.VolumeDiscount';
            const result = await Ergo.contractCallNamePromise(contractName);
            result.should.equal('orgXaccordprojectXvolumediscountXVolumeDiscount');
        });
    });

    describe('#parsefail', function () {
        it('should fail when Ergo does not parse', async function () {
            const ergoFile = Path.resolve('test', 'data/bad-logic', 'logic.ergo');
            const ergoContent = Fs.readFileSync(ergoFile, 'utf8');
            const ctoFile = Path.resolve('test', 'data/bad-logic', 'model.cto');
            const ctoContent = Fs.readFileSync(ctoFile, 'utf8');
            const result = await Ergo.compile([{ 'name': ergoFile, 'content' : ergoContent }], [{ 'name': ctoFile, 'content' : ctoContent }], 'es6', false);
            result.error.kind.should.equal('ParseError');
            result.error.message.should.equal('Parse error');
            result.error.locstart.should.deep.equal({ 'line' : 17, 'character' : 20 });
            result.error.locend.should.deep.equal({ 'line' : 17, 'character' : 23 });
        });
    });
    describe('#parseerrormessage', function () {
        it('should format parse error', async function () {
            const result = await Ergo.ergoErrorToString({ 'kind' : 'ParseError', 'message' : 'Parse error', 'verbose' : 'Parse error (at file ./test/data/bad-logic/logic.ergo line 17 col 20). \ncontract HelloWorld ovr TemplateModel {\n                    ^^^                ', 'locstart' : { 'line' : 16, 'character' : 25 }, 'locend' : { 'line' : 16, 'character' : 26 } });
            result.should.deep.equal('Parse error');
        });
    });
    describe('#verboseparseerrormessage', function () {
        it('should format verbose parse error', async function () {
            const result = await Ergo.ergoVerboseErrorToString({ 'kind' : 'ParseError', 'message' : 'Parse error', 'verbose' : 'Parse error (at file ./test/data/bad-logic/logic.ergo line 17 col 20). \ncontract HelloWorld ovr TemplateModel {\n                    ^^^                ', 'locstart' : { 'line' : 16, 'character' : 25 }, 'locend' : { 'line' : 16, 'character' : 26 } });
            result.should.deep.equal('Parse error (at file ./test/data/bad-logic/logic.ergo line 17 col 20). \ncontract HelloWorld ovr TemplateModel {\n                    ^^^                ');
        });
    });
    describe('#compilationerrormessage', function () {
        it('should format compilation error', async function () {
            const result = await Ergo.ergoErrorToString({ 'kind' : 'CompilationError', 'message' : 'Import not found: org.accordproject.test', 'locstart' : { 'line' : -1, 'character' : -1 }, 'locend' : { 'line' : -1, 'character' : -1 } });
            result.should.deep.equal('Import not found: org.accordproject.test');
        });
    });
    describe('#compile', function () {
        it('should compile a smart Ergo contract to JavaScript (ES5)', async function () {
            const ergoFile = Path.resolve('test', 'data/helloworld', 'logic.ergo');
            const ergoContent = Fs.readFileSync(ergoFile, 'utf8');
            const ctoFile = Path.resolve('test', 'data/helloworld', 'model.cto');
            const ctoContent = Fs.readFileSync(ctoFile, 'utf8');
            const result = await Ergo.compile([{ 'name': ergoFile, 'content' : ergoContent }], [{ 'name': ctoFile, 'content' : ctoContent }], 'es5', false);
            result.success.should.not.be.null;
        });
        it('should compile a smart Ergo contract to JavaScript (ES6)', async function () {
            const ergoFile = Path.resolve('test', 'data/helloworld', 'logic.ergo');
            const ergoContent = Fs.readFileSync(ergoFile, 'utf8');
            const ctoFile = Path.resolve('test', 'data/helloworld', 'model.cto');
            const ctoContent = Fs.readFileSync(ctoFile, 'utf8');
            const result = await Ergo.compile([{ 'name': ergoFile, 'content' : ergoContent }], [{ 'name': ctoFile, 'content' : ctoContent }], 'es6', false);
            result.success.should.not.be.null;
        });
        it('should compile and link a smart Ergo contract to JavaScript (ES5)', async function () {
            const ergoFile = Path.resolve('test', 'data/helloworld', 'logic.ergo');
            const ergoContent = Fs.readFileSync(ergoFile, 'utf8');
            const ctoFile = Path.resolve('test', 'data/helloworld', 'model.cto');
            const ctoContent = Fs.readFileSync(ctoFile, 'utf8');
            const result = await Ergo.compile([{ 'name': ergoFile, 'content' : ergoContent }], [{ 'name': ctoFile, 'content' : ctoContent }], 'es5', true);
            result.success.should.not.be.null;
        });
        it('should compile and link a smart Ergo contract to JavaScript (ES6)', async function () {
            const ergoFile = Path.resolve('test', 'data/helloworld', 'logic.ergo');
            const ergoContent = Fs.readFileSync(ergoFile, 'utf8');
            const ctoFile = Path.resolve('test', 'data/helloworld', 'model.cto');
            const ctoContent = Fs.readFileSync(ctoFile, 'utf8');
            const result = await Ergo.compile([{ 'name': ergoFile, 'content' : ergoContent }], [{ 'name': ctoFile, 'content' : ctoContent }], 'es6', true);
            result.success.should.not.be.null;
        });
    });
    describe('#compilehellocicero', function () {
        it('should compile a smart Ergo contract for Cicero', async function () {
            const ergoFile = Path.resolve('test', 'data/helloworld', 'logic.ergo');
            const ergoContent = Fs.readFileSync(ergoFile, 'utf8');
            const ctoFile = Path.resolve('test', 'data/helloworld', 'model.cto');
            const ctoContent = Fs.readFileSync(ctoFile, 'utf8');
            const result = await Ergo.compile([{ 'name': ergoFile, 'content' : ergoContent }], [{ 'name': ctoFile, 'content' : ctoContent }], 'cicero', false);
            result.success.should.not.be.null;
        });
    });
    describe('#compilelatedeliveryfail', function () {
        it('should fail when compiling a smart Ergo contract to JavaScript', async function () {
            const ergoFile = Path.resolve('test', 'data/latedeliveryandpenalty', 'logic.ergo');
            const ergoContent = Fs.readFileSync(ergoFile, 'utf8');
            const ctoFile = Path.resolve('test', 'data/latedeliveryandpenalty', 'model.cto');
            const ctoContent = Fs.readFileSync(ctoFile, 'utf8');
            const result = await Ergo.compile([{ 'name': ergoFile, 'content' : ergoContent }], [{ 'name': ctoFile, 'content' : ctoContent }], 'es6', false);
            result.should.deep.equal({ 'error' : { 'kind' : 'CompilationError', 'message': 'Import not found: org.accordproject.test', 'verbose' : 'Compilation error. Import not found: org.accordproject.test', 'locstart' : { 'line' : -1, 'character' : -1 }, 'locend' : { 'line' : -1, 'character' : -1 } } });
        });
    });
    describe('#compilelatedeliveryandlinkfail', function () {
        it('should fail when compiling and linking a smart Ergo contract to JavaScript', async function () {
            const ergoFile = Path.resolve('test', 'data/latedeliveryandpenalty', 'logic.ergo');
            const ergoContent = Fs.readFileSync(ergoFile, 'utf8');
            const ctoFile = Path.resolve('test', 'data/latedeliveryandpenalty', 'model.cto');
            const ctoContent = Fs.readFileSync(ctoFile, 'utf8');
            const result = await Ergo.compile([{ 'name': ergoFile, 'content' : ergoContent }], [{ 'name': ctoFile, 'content' : ctoContent }], 'es6', true);
            result.should.deep.equal({ 'error' : { 'kind' : 'CompilationError', 'message': 'Import not found: org.accordproject.test', 'verbose' : 'Compilation error. Import not found: org.accordproject.test', 'locstart' : { 'line' : -1, 'character' : -1 }, 'locend' : { 'line' : -1, 'character' : -1 } } });
        });
    });
    describe('#parsecto', function () {
        it('should parse CTO', async function () {
            const ctoText = Fs.readFileSync(Path.resolve('test', 'data/helloworld', 'model.cto'), 'utf8');
            const result = Ergo.parseCTOtoJSON(ctoText);
            result.should.not.be.null;
        });
    });
});
