///<reference path="node_modules/makerjs/index.d.ts" />
var makerjs = require('makerjs');
var firstRender = true;
//const fs = require('fs');
var App = /** @class */ (function () {
    function App() {
        var _this = this;
        this.renderCurrent = function () {
            if (firstRender) {
                _this.selectFamily.selectedIndex = 0;
                for (var i = 0; i < _this.selectFamily.options.length; i++) {
                    if(_this.selectFamily.options[i].value == "Lobster"){
                        _this.selectFamily.selectedIndex = i;
                        break;
                    }
                }
                //console.log(_this.selectFamily.value);
                firstRender = false;
            }
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
        this.canvas = document.getElementById("__processing0");
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
            var samples = 0;
            if(text != ""){
                var modelSize = makerjs.measure.modelExtents(textModel);
                var scale = Math.min(_this.canvas.width/modelSize.width*0.9, _this.canvas.width/modelSize.height*0.8);
                var minLength = 4 / scale;
                var samples = Math.pow(2, Math.ceil(Math.log(totalLength / minLength) / Math.log(2)));
            }

            var points = [];
            for (var i in chains) {
                var fraction = Math.round(lengths[i] / totalLength * samples);//math.floor(p.length() / totalLength * samples)
                if (i == chains.length-1) {
                    fraction += samples - (fraction + points.length);
                }
                var p2a = makerjs.chain.toPoints(chains[i], lengths[i]/fraction);
                //console.log(points.length);
                //console.log(p2a.length);
                points = points.concat(p2a);
            }
            //console.log(points.length);
            //var svg = makerjs.exporter.toSVG(textModel);
            //_this.renderDiv.innerHTML = svg;
            //_this.outputTextarea.value = svg;

            /*for (var i in points) {
                points[i][0] = Math.round(points[i][0]*100)/100;
                points[i][1] = Math.round(points[i][1]*100)/100;
            }*/

            SamplePoints = points;
        });
    };
    return App;
}());
var app = new App();
window.onload = function () {
    app.init();
    app.getGoogleFonts('AIzaSyAOES8EmKhuJEnsn9kS1XKBpxxp-TgN8Jc');
    //value="lobster" selectedIndex="557"
};
