package objects;

class Item {
    public var name:String;
    public var price:Int;

    public function new(name:String, price:Int = -1) {
        this.name = name;
        this.price = price == -1 ? getDefaultPrice(name) : price;
    }

    public function clone():Item {
        return new Item(name, price);
    }

    public static function getDefaultPrice(name:String):Int {
        return switch (name) {
            case 'Ice': 4;
            case 'Preserved food package': 12;
            case 'Fuel': 18;
            case 'Food': 9;
            case 'Charge': 10;
            case 'Blanket': 6;
            case 'Reactor': 8000;
            default: 4000;
        };
    }
}
