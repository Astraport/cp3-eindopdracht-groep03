package be.devine.cp3.billsplit.mobile.view {

import be.devine.cp3.billsplit.Application;
import be.devine.cp3.billsplit.model.BillModel;
import be.devine.cp3.billsplit.model.BillsCollection;
import be.devine.cp3.billsplit.model.PeopleCollection;
import be.devine.cp3.billsplit.model.service.SplitService;
import be.devine.cp3.billsplit.vo.PersonVO;
import be.devine.cp3.billsplit.vo.PersonVO;

import feathers.controls.Button;
import feathers.controls.Label;
import feathers.controls.List;
import feathers.controls.PanelScreen;
import feathers.controls.ScrollContainer;
import feathers.controls.renderers.IListItemRenderer;
import feathers.data.ListCollection;
import feathers.themes.controls.SwipeListItemRenderer;

import starling.display.DisplayObject;
import starling.events.Event;

public class BillSplitView extends PanelScreen{

    public static const ADDPERSONVIEW:String = "addPersonView";

    private var peopleCollection:PeopleCollection;
    private var billsCollection:BillsCollection;

    private var arrPeople:Array;
    private var arrPrices:Array;

    private var peopleList:List;
    private var saveBtn:Button;
    private var addPersonBtn:Button;
    private var totalTxt:Label;
    private var restTxt:Label;
    private var billTotal:Number;
    private var rest:Number;

    public function BillSplitView() {
        peopleCollection = PeopleCollection.getInstance();
        billsCollection = BillsCollection.getInstance();

        /* Header */
        headerProperties.title = billsCollection.currentBill.name;

        splitBill();

        saveBtn = new Button();
        saveBtn.label = 'Save';
        saveBtn.addEventListener(Event.TRIGGERED, saveButtonTriggeredHandler);
        headerProperties.rightItems = new <DisplayObject>[saveBtn];

        /* Footer */
        footerFactory = customFooterFactory;

        /* List */
        peopleList = new List();
        peopleList.itemRendererFactory = function():IListItemRenderer{
            var renderer:SwipeListItemRenderer = new SwipeListItemRenderer();
            return renderer;
        };
        peopleList.addEventListener(Event.CHANGE, peopleListChangeHandler);
        peopleList.addEventListener(SwipeListItemRenderer.EDIT, editPersonHandler);
        peopleList.addEventListener(SwipeListItemRenderer.DELETE, deletePersonHandler);
        addChild(peopleList);

        peopleCollection.loadPeople(billsCollection.currentBill.id);
        addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);

        display();
    }

    /* Starling events */
    private function addedToStageHandler(e:Event):void {
        removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
        stage.addEventListener(Event.RESIZE, resizeHandler);
        resize();
    }

    private function resizeHandler(e:Event):void {
        resize();
    }

    private function addPersonBtnTriggeredHandler(e:Event):void {
        dispatchEventWith(ADDPERSONVIEW, false);
    }

    private function editPersonHandler(e:Event):void {
        peopleCollection.currentPerson = peopleList.selectedItem as PersonVO;
        dispatchEventWith(Application.ADDPERSONVIEW, false);
    }

    private function deletePersonHandler(e:Event):void {
        // selectedItem = null
        peopleCollection.currentPerson = peopleList.selectedItem as PersonVO;
        peopleCollection.deleteCurrentPerson(peopleCollection.currentPerson.id, billsCollection.currentBill.id);
        display();
        splitBill();
    }


    private function peopleListChangeHandler(e:Event):void {
        // komt niet in deze functie
        //trace("[BillSplitView]: selected item: " + peopleList.selectedItem as PersonVO); //TODO
    }

    private function saveButtonTriggeredHandler(e:Event):void {
        dispatchEventWith(Application.BILLSVIEW);
    }

    /* Functions */
    private function customFooterFactory():ScrollContainer{
        var container:ScrollContainer = new ScrollContainer();
        container.nameList.add( ScrollContainer.ALTERNATE_NAME_TOOLBAR );
        container.horizontalScrollPolicy = ScrollContainer.SCROLL_POLICY_OFF;
        container.verticalScrollPolicy = ScrollContainer.SCROLL_POLICY_OFF;

        addPersonBtn = new Button;
        addPersonBtn.label = "Add Person";
        addPersonBtn.addEventListener(Event.TRIGGERED, addPersonBtnTriggeredHandler);
        container.addChild(addPersonBtn);

        billTotal = billsCollection.currentBill.total;
        totalTxt = new Label();
        totalTxt.text = "Total: " + billTotal + " euro";
        restTxt = new Label();
            if(billsCollection.currentBill.billType == "shared"){
                restTxt.text = "Shared price: " + rest + " euro";
            }else {
                restTxt.text = "Rest: " + rest + " euro";
            }
        trace("[BillSplitView] rest: " + rest);

        container.addChild(totalTxt);
        container.addChild(restTxt);

        return container;
    }

    private function pushPeople():void {
        arrPeople = [];
        arrPrices = [];
        peopleCollection.loadPeople(billsCollection.currentBill.id);

        for each( var person:PersonVO in peopleCollection.people ){
            arrPeople.push(person);
            arrPrices.push(person.total);
        }

        trace("[BillSplitView]: " + arrPeople);
    }

    private function  splitBill():void {

        pushPeople();

        trace(billsCollection.currentBill.billType);

        switch(billsCollection.currentBill.billType){

            case "shared":
                rest = SplitService.shared(billsCollection.currentBill.total,arrPeople);
                break;
            case "ownprice":
                rest = SplitService.ownPrice(billsCollection.currentBill.total, arrPrices);
                break;
            case "percentage":
                rest = SplitService.percentage(billsCollection.currentBill.total, arrPrices);
                break;
            default:
                rest = SplitService.shared(billsCollection.currentBill.total,arrPeople);
                break;
        }

        trace("split: rest: " + rest);
    }


    private function display():void{
        peopleList.dataProvider = new ListCollection(peopleCollection.people);
    }

    private function resize():void{
        peopleList.setSize(stage.stageWidth, stage.stageHeight);
    }

}}