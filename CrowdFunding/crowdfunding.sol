// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract crowdfunding{
    
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public targetAmount;
    uint public raisedAmount;
    uint public noOfContributors;

    struct Request{
        string description;
        uint value;
        address payable receipient;

        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    mapping(uint=>Request) public requests;
    uint public numRequests;


    constructor(uint _targetAmount, uint _deadline){
        targetAmount = _targetAmount;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    // receive eth from outside to this contract
    function sendEth() public payable{
        require(block.timestamp < deadline, "Sorry!! Deadline has already passed.");
        require(msg.value >= minimumContribution, "Sorry!! you have to pay minimum 100 wei.");

        if(contributors[msg.sender] == 0) noOfContributors++;

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;

    }


    function getContractBalance() public view returns(uint){
        // anyone can check the total balance of this contract.
        return address(this).balance;
    }


    function refund() public{
        require(block.timestamp > deadline && raisedAmount < targetAmount, "Sorry, refund has not started yet for anyone because either deadline has not cross or the raised amount is equal or more than target amount.");
        require(contributors[msg.sender] > 0, "You haven't contributed.");

        address payable receiverAddress = payable(msg.sender);
        receiverAddress.transfer(contributors[msg.sender]);

        raisedAmount -= contributors[msg.sender];
        // TODO: cann't we delete this contributor from contributors list/map
        contributors[msg.sender] = 0;
        noOfContributors--;

    }


    modifier onlyManager(){
        require(msg.sender == manager, "Only manager can call this feature.");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.receipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender] > 0, "Sorry!! You have to contribute first in order to eligible for vote.");
        require(_requestNo <= numRequests && _requestNo >= 0, "Invalid request number.");

        Request storage currentRequest = requests[_requestNo];

        require(currentRequest.voters[msg.sender] == false, "Opps!! you already put your vote for this request. You can only vote once per request.");
        currentRequest.voters[msg.sender] = true;
        currentRequest.noOfVoters++;
    }


    function makePayment(uint _requestNo) public onlyManager{
        // check valid request number
        require(_requestNo <= numRequests, "Invalid Request Number.");

        // check if raised amount is enough
        require(raisedAmount >= targetAmount, "Targer equal money has not been raised so far.");

        Request storage currentRequest = requests[_requestNo];

        // check if this request has not aleady been transferred
        require(currentRequest.completed == false, "We already transferred the fund to this request.");

        // check if more than 50% of contributors vote for this request
        require(currentRequest.noOfVoters > noOfContributors / 2, "Majority voters does not support this request");

        currentRequest.receipient.transfer(currentRequest.value);
        currentRequest.completed = true;

        // reset valiable
        raisedAmount -= currentRequest.value;
        
    }


}