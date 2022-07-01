/// <reference path="../node_modules/@types/jquery/index.d.ts"/>
/// <reference path="../node_modules/@types/angular/index.d.ts"/>
/// <reference path="../node_modules/@types/bootstrap/index.d.ts"/>
/// <reference path="../node_modules/@types/angular-ui-bootstrap/index.d.ts"/>

namespace mainModule {
    interface IMainControllerScope extends ng.IScope {
    }
    
    export let mainModule: angular.IModule = angular.module("mainModule", []);
    
    export class MainController {
        static $inject: Array<string> = ["$scope"];
        
        constructor(private $scope: IMainControllerScope) {
        }
    }
    
    mainModule.controller("MainController", MainController);
}