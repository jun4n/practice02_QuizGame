// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console.sol";

contract Quiz{
    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
   }
    
    mapping(uint256 => mapping(address => uint256)) public bets;
    mapping(address => uint256) public winner;
    uint public vault_balance;
    address private owner;
    Quiz_item[] public quizzes;
    mapping(uint256 => string) private quiz_answer;
    constructor () {
        owner = msg.sender;
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
        quiz_answer[0] = "2";
    }

    // 아무나 퀴즈를 생성할 수 없다.
    function addQuiz(Quiz_item memory q) public {
        require(msg.sender == owner);
        quiz_answer[q.id - 1] = q.answer;
        q.answer = "";
        quizzes.push(q);
    }

    function getAnswer(uint quizId) public view returns (string memory){
        require(msg.sender == owner);
        return quiz_answer[quizId - 1];
    }
    // 1 => index 0
    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        return quizzes[quizId -1];
    }

    function getQuizNum() public view returns (uint){
        return quizzes.length;
    }

    function betToPlay(uint quizId) public payable{
        require(msg.value <= quizzes[quizId - 1].max_bet);
        require(msg.value >= quizzes[quizId - 1].min_bet);
        bets[quizId - 1][msg.sender] += msg.value;
        
    }
    // solve실패시 배팅액 초기화
    // solve시도시 vault_balance에 배팅액 넣기
    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        require(bets[quizId - 1][msg.sender] > 0, "Not Betted");
        vault_balance += bets[quizId - 1][msg.sender];

        if(keccak256(abi.encodePacked(quiz_answer[quizId - 1])) == keccak256(abi.encodePacked(ans))){
            winner[msg.sender] = quizId;
            return true;
        }
        
        bets[quizId - 1][msg.sender] = 0;
        return false;
    }
    // 맞출경우 배팅액의 두배를 준다.
    // 상금만큼 vault_balance에서 차감?
    function claim() public {
        require(winner[msg.sender] != 0, "You are not winner");
        uint reward = bets[winner[msg.sender] - 1][msg.sender] * 2;
        require(address(this).balance >= reward, "Can't pay");
        (bool success, ) = (msg.sender).call{value:reward}("");
        //payable(msg.sender).transfer(reward);
        require(success,"Transaction failed");
    }
    receive() external payable {
    }
}
