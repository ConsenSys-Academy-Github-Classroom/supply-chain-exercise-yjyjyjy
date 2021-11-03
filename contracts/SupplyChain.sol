// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

contract SupplyChain {
  // <owner>
  address public owner;
  uint public skuCount;
  // <items mapping>
  mapping(uint => Item) public items;

  // <enum State: ForSale-0 , Sold-1, Shipped-2, Received-3>
  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  // <struct Item: name, sku, price, state, seller, and buyer>
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  /*
   * Events
   */

  // <LogForSale event: sku arg>
  event LogForSale(uint sku);
  // <LogSold event: sku arg>
  event LogSold(uint sku);
  // <LogShipped event: sku arg>
  event LogShipped(uint sku);
  // <LogReceived event: sku arg>
  event LogReceived(uint sku);


  /*
   * Modifiers
   */
  modifier isOnwer {
    require(msg.sender == owner, "This execution is reserved for owner only");
    _;
  }

  modifier verifyCaller (address _address) {
    require (msg.sender == _address);
    _;
  }

  modifier paidEnough(uint _price) {
    require(msg.value >= _price);
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    // items[_sku].buyer.transfer(amountToRefund);
    (bool sent,) = items[_sku].buyer.call{value:amountToRefund}("");
    require(sent, "Failed to send Ether");
  }

  // For each of the following modifiers, use what you learned about modifiers
  // to give them functionality. For example, the forSale modifier should
  // require that the item with the given sku has the state ForSale. Note that
  // the uninitialized Item.State is 0, which is also the index of the ForSale
  // value, so checking that Item.State == ForSale is not sufficient to check
  // that an Item is for sale. Hint: What item properties will be non-zero when
  // an Item has been added?

  modifier forSale(uint _sku){
    require(items[_sku].state == State.ForSale && items[_sku].price > 0);
    _;
  }

  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold);
    _;
  }
  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped);
    _;
  }
  modifier received(uint _sku) {
    require(items[_sku].state == State.Received);
    _;
  }

  constructor() {
    // 1. Set the owner to the transaction sender
    // 2. Initialize the sku count to 0. Question, is this necessary?
     owner = msg.sender;
     items[0] = Item(
       {
        name: 'banana',
        sku: 0,
        price: 100,
        state: State.ForSale,
        seller: payable(msg.sender),
        buyer: payable(address(0))
      });
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    // 1. Create a new item and put in array
    items[skuCount]=
      Item({
        name: _name,
        sku: skuCount,
        price: _price,
        state: State.ForSale,
        seller: payable(msg.sender),
        buyer: payable(address(0))
      });
    // 2. Increment the skuCount by one
    skuCount = skuCount + 1;
    // 3. Emit the appropriate event
    emit LogForSale(skuCount);
    // 4. return true
    return true;

    // hint:
    // items[skuCount] = Item({
    //  name: _name,
    //  sku: skuCount,
    //  price: _price,
    //  state: State.ForSale,
    //  seller: msg.sender,
    //  buyer: address(0)
    //});
    //
    //skuCount = skuCount + 1;
    // emit LogForSale(skuCount);
    // return true;
  }

  // Implement this buyItem function.
  // 1. it should be payable in order to receive refunds
  // 5. this function should use 3 modifiers to check
  //    - if the item is for sale,
  //    - if the buyer paid enough,
  //    - check the value after the function is called to make
  //      sure the buyer is refunded any excess ether sent.
  function buyItem(uint sku) public forSale(sku) paidEnough(msg.value) checkValue(sku) payable {
  // 2. this should transfer money to the seller,
    (bool sent,) = items[sku].seller.call{value:items[sku].price}("");
    require(sent, "Failed to send Ether");
  // 3. set the buyer as the person who called this transaction,
    items[sku].buyer = payable(msg.sender);
  // 4. set the state to Sold.
    items[sku].state = State.Sold;
  // 6. call the event associated with this function!
    emit LogSold(sku);
  }

  // 1. Add modifiers to check:
  //    - the item is sold already
  //    - the person calling this function is the seller.
  // 2. Change the state of the item to shipped.
  // 3. call the event associated with this function!
  function shipItem(uint sku) sold(sku) verifyCaller(items[sku].seller) public {
    items[sku].state = State.Shipped;
    emit LogShipped(sku);
  }

  // 1. Add modifiers to check
  //    - the item is shipped already
  //    - the person calling this function is the buyer.
  // 2. Change the state of the item to received.
  // 3. Call the event associated with this function!
  function receiveItem(uint sku) shipped(sku) verifyCaller(items[sku].buyer) public {
    items[sku].state = State.Received;
    emit LogReceived(sku);
  }

  // Uncomment the following code block. it is needed to run tests
  function fetchItem(uint _sku) public view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
  {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}
