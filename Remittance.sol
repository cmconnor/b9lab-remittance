pragma solidity ^0.4.4;

contract Remittance{
	struct Tx{
		address from_addr;
		address to_addr;
		uint deadline;
		uint amount;
	}
	
	mapping (bytes32=>Tx) public TxMap;
	mapping (bytes32=>bool) public completed;
        bool public kill_switch;
        address public owner;
	uint public royalties;

    
 	   event LogNewTx(address indexed from, address indexed to, bytes32 indexed hashkey, uint deadline,uint amount);
	event LogCompleted(address indexed from, address indexed to, bytes32 indexed hashkey,uint amount);
	event LogReturned(address indexed from, bytes32 indexed hashkey, uint amount);

	function Remittance()public{
		owner=msg.sender;
	}
	
	function getHash(address to_addr, bytes32 key1)public pure returns(bytes32){
		return keccak256(key1,to_addr);
	}

	function newTx(address to, bytes32 hashkey, uint deadline)public payable returns(bool){
		assert(to!=0);
		assert(hashkey!="");
		assert(TxMap[hashkey].from_addr==0);
		assert(deadline>0);
		assert(msg.value>0);
		assert(!kill_switch);
		uint royalCut=msg.value/100; //1% cut of value goes to contract as a royalty
		royalties+=royalCut;
		uint purse=msg.value-royalCut;
		TxMap[hashkey]=Tx({from_addr:msg.sender,to_addr:to,deadline:deadline+block.number,amount:purse});
		LogNewTx(msg.sender,to,hashkey,deadline+block.number,msg.value);
		return true;
	}


	function collect(bytes32 key1,bytes32 hashkey)public returns(bool){
	    assert(hashkey==getHash(TxMap[hashkey].to_addr,key1));
	    assert(TxMap[hashkey].from_addr!=0);
	    assert(completed[hashkey]==false);
	    completed[hashkey]=true;
        address(TxMap[hashkey].to_addr).transfer(TxMap[hashkey].amount);
        LogCompleted(TxMap[hashkey].from_addr,TxMap[hashkey].to_addr,hashkey,TxMap[hashkey].amount);
	    return true;
	}

	function pastDeadline(bytes32 hashkey)public returns(bool){
	    assert(hashkey!=0);
	    assert(completed[hashkey]==false);
	    assert(TxMap[hashkey].from_addr==msg.sender);
	    assert(TxMap[hashkey].deadline<block.number);
	    completed[hashkey]=true;
	    TxMap[hashkey].from_addr.transfer(TxMap[hashkey].amount);
	    LogReturned(TxMap[hashkey].from_addr,hashkey,TxMap[hashkey].amount);
	    return true;
	}

	function killSwitch()public returns(bool){
	    assert(msg.sender==owner);
	    kill_switch=true;
	    return true;
	}

	function collectRoyalties()public returns(bool){
	    assert(msg.sender==owner);
	    assert(royalties>0);
	    uint payout=royalties;
            royalties=0;
            owner.transfer(payout);
	    return true;
	}
}


