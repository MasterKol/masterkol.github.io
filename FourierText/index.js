///<reference path="node_modules/makerjs/index.d.ts" />
var makerjs = require('makerjs');
//const fs = require('fs');
var App = /** @class */ (function () {
    function App() {
        var _this = this;
        this.renderCurrent = function () {
            _this.render(_this.selectFamily.selectedIndex, _this.selectVariant.selectedIndex, _this.textInput.value, 100, false, true, false, 2);
        };
        this.loadVariants = function () {
            _this.selectVariant.options.length = 0;
            var f = _this.fontList.items[_this.selectFamily.selectedIndex];
            var v = f.variants.forEach(function (v) { return _this.addOption(_this.selectVariant, v); });
            _this.renderCurrent();
        };
    }
    App.prototype.init = function () {
        this.selectFamily = this.$('#font-select');
        this.selectVariant = this.$('#font-variant');
        //this.unionCheckbox = this.$('#input-union');
        //this.kerningCheckbox = this.$('#input-kerning');
        //this.separateCheckbox = this.$('#input-separate');
        this.textInput = this.$('#input-text');
        //this.bezierAccuracy = this.$('#input-bezier-accuracy');
        //this.sizeInput = this.$('#input-size');
        //this.renderDiv = this.$('#svg-render');
        this.outputTextarea = this.$('#output-svg');
        this.functions = this.$('#functions');
    };
    App.prototype.handleEvents = function () {
        nodeloadvariants = this.loadVariants; // this.selectFamily.onchange
        /*this.selectVariant.onchange =
            this.textInput.onchange =
                this.textInput.onkeyup =
                    this.sizeInput.onkeyup =
                        this.unionCheckbox.onchange =
                            this.kerningCheckbox.onchange =
                                this.separateCheckbox.onchange =
                                    this.bezierAccuracy.onchange =
                                        this.renderCurrent;*/
        //this.selectVariant.onchange =
        //    this.textInput.onkeyup =
        //        this.renderCurrent;
        noderender = this.renderCurrent;
        this.testValue = 10;
    };
    App.prototype.$ = function (selector) {
        return document.querySelector(selector);
    };
    App.prototype.addOption = function (select, optionText) {
        var option = document.createElement('option');
        option.text = optionText;
        select.options.add(option);
    };
    App.prototype.getGoogleFonts = function (apiKey) {
        var _this = this;
        var xhr = new XMLHttpRequest();
        xhr.open('get', 'https://www.googleapis.com/webfonts/v1/webfonts?key=' + apiKey, true);
        xhr.onloadend = function () {
            _this.fontList = JSON.parse(xhr.responseText);
            _this.fontList.items.forEach(function (font) { return _this.addOption(_this.selectFamily, font.family); });
            _this.loadVariants();
            _this.handleEvents();
        };
        xhr.send();
    };
    App.prototype.render = function (fontIndex, variantIndex, text, size, union, kerning, separate, bezierAccuracy) {
        var _this = this;
        var f = this.fontList.items[fontIndex];
        var v = f.variants[variantIndex];
        var url = f.files[v].substring(5); //remove http:
        opentype.load(url, function (err, font) {
            //generate the text using a font
            var textModel = new makerjs.models.Text(font, text, size, union, false, bezierAccuracy, { kerning: kerning });
            /*if (separate) {
                for (var i in textModel.models) {
                    textModel.models[i].layer = i;
                }
            }*/

            var chains = [];
            for (var i in textModel.models) {
                textModel.models[i].layer = i;
                
                chains = chains.concat(makerjs.model.findChains(textModel.models[i]));
            }

            var lengths = [];
            var totalLength = 0;
            for (var i in chains) {
                lengths.push(chains[i].pathLength);
                totalLength = totalLength + lengths[i];
            }
            var minLength = 2;
            var samples = Math.pow(2, Math.ceil(Math.log(totalLength/minLength)/Math.log(2)));
            console.log(samples);

            var points = [];
            for (var i in chains) {
                var fraction = lengths[i] / totalLength * samples;//math.floor(p.length() / totalLength * samples)
                if (i == chains.length-1) {
                    fraction += samples - (fraction + points.length);
                }
                points = points.concat(makerjs.chain.toPoints(chains[i], lengths[i]/fraction));
            }
            //console.log(points.length);
            var svg = makerjs.exporter.toSVG(textModel);
            //_this.renderDiv.innerHTML = svg;
            //_this.outputTextarea.value = svg;


            //_this.outputTextarea.value = UnArchive(textModel.models[0].paths);//textModel.models[1].type;
            _this.outputTextarea.value = points;//makerjs.chain.toPoints(chains[1], 10);//makerjs.point.middle(textModel.models[0].paths);
        });
    };
    return App;
}());
var app = new App();
window.onload = function () {
    app.init();
    app.getGoogleFonts('AIzaSyAOES8EmKhuJEnsn9kS1XKBpxxp-TgN8Jc');
};
