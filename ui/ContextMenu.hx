package ui;
import Eight;
import Game;
import Character;
import Character.MoveJob;
import Character.RepairJob;
import Character.UseJob;
import Character.HaulJob;
import Character.SleepJob;
import ui.MainframeEditor;
import util.Texture.Button;
import util.Texture.FontManager;
import util.Math.Vec3;
import sdl.Event;
import util.Sequence;
import objects.Extendable;
import objects.Items;
import objects.Objects;

class ContextMenu {
    var buttonMove:Button;
    var buttonRepair:Button;
    var buttonUse:Button;
    var buttonHaul:Button;
    var buttonSleep:Button;
    var buttonAttach:Button;
    var buttonDeattach:Button;
    var buttonSalvage:Button;
    var buttonPlace:Button;
    var buttonTrade:Button;
    var buttonProgram:Button;
    static var editor:MainframeEditor = new MainframeEditor();

    var pos:Vec3;
    var selectedObj:ExtendableObject;
    var selectedChar:Character;
    var targetPos:Vec3;

    public inline function new() {
        buttonMove = new Button('Move   ');
        buttonMove.clicked = function() {
            if (selectedChar != null && targetPos != null) {
                selectedChar.setSingleJob(new MoveJob(targetPos));
            }
            setVisible(false);
        };
        buttons.push(buttonMove);

        buttonRepair = new Button('Repair ');
        buttonRepair.clicked = function() {
            if (selectedChar != null && selectedObj != null) {
                selectedChar.setSingleJob(new RepairJob(selectedObj));
            }
            setVisible(false);
        };
        buttons.push(buttonRepair);

        buttonUse = new Button('Use     ');
        buttonUse.clicked = function() {
            if (selectedChar != null && selectedObj != null) {
                selectedChar.setSingleJob(new UseJob(selectedObj));
            }
            setVisible(false);
        };
        buttons.push(buttonUse);

        buttonHaul = new Button('Haul    ');
        buttonHaul.clicked = function() {
            if (selectedChar != null && selectedObj != null) {
                var source = selectedObj;
                var destination = Game.currentShip.core != selectedObj ? Game.currentShip.core : findHaulDestination(selectedObj);

                if (Std.isOfType(selectedObj, Vendor)) {
                    var vendor:Vendor = cast selectedObj;
                    var storage:Storage = vendor.getTradeStorage();
                    var tradeCell:ExtendableObject = storage != null ? storage : vendor;
                    if (tradeCell.inventory.length == 0 && Game.currentShip.core.inventory.length > 0) {
                        source = Game.currentShip.core;
                        destination = tradeCell;
                    } else {
                        source = tradeCell;
                        destination = Game.currentShip.core;
                    }
                }

                if (destination != null && source != null && source.inventory.length > 0) {
                    var itemName = source.inventory[0].name;
                    selectedChar.setSingleJob(new HaulJob(source, destination, itemName));
                }
            }
            setVisible(false);
        };
        buttons.push(buttonHaul);

        buttonSleep = new Button('Sleep   ');
        buttonSleep.clicked = function() {
            if (selectedChar != null && selectedObj != null) {
                selectedChar.setSingleJob(new SleepJob(selectedObj));
            }
            setVisible(false);
        };
        buttons.push(buttonSleep);


        buttonAttach = new Button('Attach ');
        buttonAttach.clicked = () -> {
            var attachOnEvent = null;
            var initialPos:Vec3 = new Vec3(0, 0, 0);
            var dot:Eight.Object = null;
            var dot2:Eight.Object = null;
            var connectorType:Int = 0;

            var finished:Bool = false;
            var _attachOnEvent = (seq, selected1:ExtendableObject, selected1Connector:Connector, dot, dot2) -> return (event:Event) -> {
                var nearest:ExtendableObject = null;
                var nearestConnector:Connector = null;

                if (finished == false) {
                    if (event.type == EventType.KeyDown && event.keyCode == 114) { //r
                        selected1.rotateLocal(-90);
                        var nPos:Vec3 = Vec3.rotate(selected1Connector.pos, -90);
                        selected1Connector = Game.currentShip.findNearestConnector(selected1, nPos, connectorType, true);
                    }

                    var result = Game.currentShip.findNearestConnectorAll(Game.worldPos, connectorType);
                    if (result == null) return seq.next();
                    nearest = result.obj;
                    nearestConnector = result.connector;

                    dot.angle = selected1.angle;
                    dot.pos = ExtendableObject.getConnectorWorldPos(selected1, selected1Connector.pos);
                    dot2.angle = nearest.angle;
                    dot2.pos = ExtendableObject.getConnectorWorldPos(nearest, nearestConnector.pos);
                    Game.currentShip.ghostConnect(nearest, selected1, nearestConnector.pos, selected1Connector.pos);
                }
                
                if (event.type == EventType.MouseDown && event.button == 1 && nearest != null) {
                    finished = true;

                    selected1.setPosV3(initialPos);
                    var char:Character = Game.characters[0];

                    

                    new Sequence()
                    .then((seq2) -> { 
                        char.setTarget(initialPos, () -> {
                            seq2.next();
                        });
                    })
                    .then((seq2) -> {
                        char.setTarget(nearest.pos, () -> {
                            seq2.next();
                        });
                    })
                    .then((seq2) -> {
                        Game.currentShip.connect(nearest, selected1, nearestConnector.pos, selected1Connector.pos);
                        trace('Attach done');
                        
                        seq2.next(); seq.next();
                    })
                    .start();
                }  else if (event.type == EventType.MouseDown && event.button == 3) {
                    selected1.setPosV3(initialPos);
                    trace('Attach canceled');
                    seq.next();
                }   
            };
            var userSelectWhereToAttach = (seq) -> {
                if(!Std.isOfType(Eight.currentSelected, ExtendableObject)) return;
                buttonAttach.word = 'Select where attach';

                var selected1:ExtendableObject = cast Eight.currentSelected; initialPos = selected1.pos;
                var selected1Connector:Connector = Game.currentShip.findNearestConnector(selected1, Game.worldPosClicked, -1, false);
                trace('Connector type: ${selected1Connector.type}');
                connectorType = selected1Connector.type;

                trace('${Game.worldPosClicked[0]}, ${Game.worldPosClicked[1]} world pos extendable');
                trace('${selected1Connector.pos[0]}, ${selected1Connector.pos[1]} local pos');
                trace('${selected1.pos[0]}, ${selected1.pos[1]} object pos');

                dot = new Eight.Object(4, 4, null, 0xee4341);
                dot2 = new Eight.Object(4, 4, null, 0xee4341);
                
                attachOnEvent = _attachOnEvent(seq, selected1, selected1Connector, dot, dot2);
                Eight.registerEventCallback(attachOnEvent);
            };

            var returnButton = (seq) -> {
                buttonAttach.word = 'Attach '; 
                this.setVisible(false);
                
                Eight.unregisterEventCallback(attachOnEvent);
                dot.destroy(); dot2.destroy();

                seq.next();
            };

            new Sequence()
            .then(userSelectWhereToAttach)
            .then(returnButton)
            .start();
        };
        buttons.push(buttonAttach);

        buttonDeattach = new Button('Deattach ');
        buttonDeattach.clicked = function() {
            if(Std.isOfType(Eight.currentSelected, ExtendableObject)) Game.currentShip.deattach(cast Eight.currentSelected);
            setVisible(false);
        }
        buttons.push(buttonDeattach);

        buttonPlace = new Button('Place    ');
        buttonPlace.clicked = function() {
        
        }
        buttons.push(buttonPlace);

        buttonSalvage = new Button('Salvage  ');
        buttonSalvage.clicked = function() {
            //setVisible(false);
            var selected1:ExtendableObject = cast Eight.currentSelected;
            var char:Character = Game.characters[0];

            char.setTarget(new Vec3(selected1.pos[0]-20, selected1.pos[1], 0), () -> {
                selected1.destroy();
            });
        }
        buttons.push(buttonSalvage);

        buttonTrade = new Button('Trade    ');
        buttonTrade.clicked = function() {
            var vendor:Vendor = Std.downcast(selectedObj, Vendor);
            if (vendor == null) return;
            var storage:Storage = vendor.getTradeStorage();

            var tradeUpdate:Float->Void = null;
            var statusText:String = 'Trade terminal ready';
            var buyIndex:Int = 0;
            var sellIndex:Int = 0;

            var bg:Eight.Object = new Eight.Object(Engine.n-100, Engine.n2-100, null, 0xFF2E312E);
            bg.zlayer = 1;
            bg.isUI = true;

            var buttonBuy:Button = new Button('Buy');
            buttonBuy.pos = new Vec3(Engine.n/2-170, 50, 0);
            buttonBuy.setVisible(true);
            buttonBuy.clicked = function() {
                if (vendor.marketInventory.length == 0) {
                    statusText = 'Vendor has nothing to sell';
                    return;
                }

                if (buyIndex >= vendor.marketInventory.length) buyIndex = vendor.marketInventory.length - 1;
                var item = vendor.marketInventory[buyIndex];
                if (item == null) return;

                if (Game.credits < item.price) {
                    statusText = 'Not enough credits';
                    return;
                }

                if (storage == null) {
                    statusText = 'No storage connected';
                    return;
                }

                Game.credits -= item.price;
                storage.inventory.push(vendor.marketInventory.splice(buyIndex, 1)[0]);
                if (buyIndex >= vendor.marketInventory.length && buyIndex > 0) buyIndex--;
                statusText = 'Bought ${item.name}; item moved to storage';
            };

            var buttonBuyPrev:Button = new Button('Prev');
            buttonBuyPrev.pos = new Vec3(Engine.n/2-280, 50, 0);
            buttonBuyPrev.setVisible(true);
            buttonBuyPrev.clicked = function() {
                if (vendor.marketInventory.length == 0) return;
                buyIndex--;
                if (buyIndex < 0) buyIndex = vendor.marketInventory.length - 1;
            };

            var buttonBuyNext:Button = new Button('Next');
            buttonBuyNext.pos = new Vec3(Engine.n/2-60, 50, 0);
            buttonBuyNext.setVisible(true);
            buttonBuyNext.clicked = function() {
                if (vendor.marketInventory.length == 0) return;
                buyIndex++;
                if (buyIndex >= vendor.marketInventory.length) buyIndex = 0;
            };

            var buttonSell:Button = new Button('Sell');
            buttonSell.pos = new Vec3(Engine.n/2+170, 50, 0);
            buttonSell.setVisible(true);
            buttonSell.clicked = function() {
                if (storage == null) {
                    statusText = 'No storage connected';
                    return;
                }

                var tradeCell = storage.inventory;
                if (tradeCell.length == 0) {
                    statusText = 'Storage is empty';
                    return;
                }

                if (sellIndex >= tradeCell.length) sellIndex = tradeCell.length - 1;
                var item = tradeCell[sellIndex];
                if (item == null) return;

                var salePrice = Std.int(Math.max(1, item.price * 0.7));
                Game.credits += salePrice;
                vendor.marketInventory.push(tradeCell.splice(sellIndex, 1)[0]);
                if (sellIndex >= tradeCell.length && sellIndex > 0) sellIndex--;
                statusText = 'Sold ${item.name} from storage for ${salePrice} cr';
            };

            var buttonSellPrev:Button = new Button('Prev');
            buttonSellPrev.pos = new Vec3(Engine.n/2+60, 50, 0);
            buttonSellPrev.setVisible(true);
            buttonSellPrev.clicked = function() {
                if (storage == null) return;
                var tradeCell = storage.inventory;
                if (tradeCell.length == 0) return;
                sellIndex--;
                if (sellIndex < 0) sellIndex = tradeCell.length - 1;
            };

            var buttonSellNext:Button = new Button('Next');
            buttonSellNext.pos = new Vec3(Engine.n/2+280, 50, 0);
            buttonSellNext.setVisible(true);
            buttonSellNext.clicked = function() {
                if (storage == null) return;
                var tradeCell = storage.inventory;
                if (tradeCell.length == 0) return;
                sellIndex++;
                if (sellIndex >= tradeCell.length) sellIndex = 0;
            };

            var buttonClose:Button = new Button('Close');
            buttonClose.pos = new Vec3(Engine.n/2, 30, 0);
            buttonClose.setVisible(true);
            buttonClose.clicked = function() {
                buttonClose.destroy();
                buttonBuy.destroy();
                buttonBuyPrev.destroy();
                buttonBuyNext.destroy();
                buttonSell.destroy();
                buttonSellPrev.destroy();
                buttonSellNext.destroy();
                bg.destroy();

                Eight.unregisterUpdateCallback(tradeUpdate);
            };

            tradeUpdate = (dt:Float) -> {
                bg.setPos(Engine.n/2, Engine.n2/2);

                var tradeCell = storage != null ? storage.inventory : [];
                FontManager.drawText('Trading with Vendor', Std.int(Engine.n/2-120), Engine.n2-90);
                FontManager.drawText('Credits: ${Game.credits}', Std.int(Engine.n/2-80), Engine.n2-115);
                FontManager.drawText(statusText, Std.int(Engine.n/2-170), 90);

                FontManager.drawText('Vendor stock', 90, Engine.n2-120);
                var i = 0;
                for (item in vendor.marketInventory) {
                    var marker = i == buyIndex ? '>' : ' ';
                    FontManager.drawText('${marker}${item.name} ${item.price}cr', 90, Engine.n2-150-18*i);
                    i++;
                }
                if (vendor.marketInventory.length == 0) {
                    FontManager.drawText('empty', 90, Engine.n2-150);
                }

                FontManager.drawText('Storage', Std.int(Engine.n/2+70), Engine.n2-120);
                var j = 0;
                for (item in tradeCell) {
                    var marker = j == sellIndex ? '>' : ' ';
                    var salePrice = Std.int(Math.max(1, item.price * 0.7));
                    FontManager.drawText('${marker}${item.name} ${salePrice}cr', Std.int(Engine.n/2+70), Engine.n2-150-18*j);
                    j++;
                }
                if (tradeCell.length == 0) {
                    FontManager.drawText(storage == null ? 'missing' : 'empty', Std.int(Engine.n/2+70), Engine.n2-150);
                }
            };

            Eight.registerUpdateCallback(tradeUpdate);
            setVisible(false);
        };
        buttons.push(buttonTrade);

        buttonProgram = new Button('Program ');
        buttonProgram.clicked = function() {
            var mainframe:Mainframe = Std.downcast(selectedObj, Mainframe);
            if (mainframe != null) {
                editor.open(mainframe);
            }
            setVisible(false);
        };
        buttons.push(buttonProgram);

        setVisible(false);
    }

    public var buttons:Array<Button> = [];
    public inline function setPos(mx:Float, my:Float) {
        pos = new Vec3(mx, my, 0);
    }

    function findHaulDestination(source:ExtendableObject):ExtendableObject {
        for (obj in Game.currentShip.objects) {
            if (obj != source) return obj;
        }
        return null;
    }

    function hideAllButtons():Void {
        for (button in buttons) {
            button.setVisible(false);
        }
    }

    public function setVisible(visible:Bool, obj:ExtendableObject=null, char:Character=null, worldTarget:Vec3=null) {
        selectedObj = obj;
        selectedChar = char;
        targetPos = worldTarget;

        hideAllButtons();

        if (!visible) return;

        if (selectedChar != null) {
            buttonMove.setVisible(worldTarget != null);
            buttonRepair.setVisible(obj != null && obj.isBroken);
            buttonUse.setVisible(obj != null && (Std.isOfType(obj, Vendor) || Std.isOfType(obj, Hydroponics) || Std.isOfType(obj, Sensor) || Std.isOfType(obj, ShipConsole)));
            buttonHaul.setVisible(obj != null && (obj.inventory.length > 0 || (Std.isOfType(obj, Vendor) && Game.currentShip.core.inventory.length > 0)));
            buttonSleep.setVisible(obj != null && Std.isOfType(obj, Bed));
        } else {
            for(button in buttons) {
                button.setVisible(true);
            }
            if (selectedObj.manager != null)
                buttonAttach.setVisible(false);
            if (selectedObj.linked.length > 0)
                buttonDeattach.setVisible(false);
            if (selectedObj.manager != null)
                buttonSalvage.setVisible(false);

            buttonMove.setVisible(false);
            buttonRepair.setVisible(false);
            buttonUse.setVisible(false);
            buttonHaul.setVisible(false);
            buttonSleep.setVisible(false);
            buttonTrade.setVisible(false);
            buttonProgram.setVisible(false);
            buttonPlace.setVisible(false);
            if (obj != null && Std.isOfType(obj, Vendor)) {
                buttonTrade.setVisible(true);
            }
            if (obj != null && Std.isOfType(obj, Mainframe)) {
                buttonProgram.setVisible(true);
            }
        }

        var w = 140;
        var i = 0; for(button in buttons) {
            if (button.show != true) continue;
            button.pos = new Vec3(pos[0]+w, pos[1]-18*i, 0.0);
            i++;
        }
    }
}
