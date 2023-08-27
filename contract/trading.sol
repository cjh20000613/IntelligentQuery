// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//500000000000000000

contract Trading{
    
    ///////////////////////////////////////////////////////////////
    /// 状态变量
    //////////////////////////////////////////////////////////////
    //////第三方机构
    //合约创建者
    address owner;
    //中介费
    uint256 immutable Fee;
    //隐私补偿费
    uint256 immutable fee;
    //数据位数
    uint256 immutable digit;
    
    //数据拥有者总数
    uint256 public dataOwnerNum;

    //交易id   
    uint256 public txID;

    //环境量
    uint256 private nounce = 0;

    //数据传输锁
    uint256 lock;

    //购买队列
    uint256 public txLock;
    //出队
    uint256 public txUnlock;

    //背包问题锁
    uint256 private packageLock; 

    ///////////////背包问题求解
    uint256[] private values;
    uint256[] private weights;
    
    ///////////////////////////////////////////////////////////////
    /// 结构体
    //////////////////////////////////////////////////////////////
    //数据拥有者
    struct dataOwner
    {
        address ownerAddr;   //数据所有者的地址
        uint256 value;      //数据价值
        uint256 privacy;    //隐私等级 
        uint256 weight;     //数据代价（价值*隐私）
        uint256 site;       //在数组中的位置
        uint256 release;    //可以提出的钱
        uint256 times;      //超时次数 （>3时进入黑名单）
    }

    //数据购买者
    struct dataConsumer
    {
        address ConsumerAddr;    //数据购买者地址
        uint256 Budget;         //预算
        uint256 privacy;        //隐私等级
        uint256 txLock;           //队列位置
        string data;            //数据
        uint256 len;            //密文长度
        uint256 times;          //加入次数
        bool lastTX;            //上次交易是否完成（初始为true）
    }

    //购买队列
    struct txLocked
    {
        address consumer;       //交易发起者
        uint256 budget;         //预算
        uint256 fee;            //中介费
        string g;               //曲线
        string h;               //公钥
        string td;              //陷门
    }

    //交易
    struct transaction
    {
        address consumer;       //交易的发起者
        uint256 startTime;      //交易开始时间
        uint256 ownerLine;      //数据提交期限
        uint256 deadline;       //交易结束时间
        uint256 budget;         //预算
        uint256 value;          //数据价值
        uint256 residual;       //剩余预算
        uint256 fee;            //隐私补偿
        uint256 txOwnerNum;     //本次交易的数据拥有者个数
        uint256[] chooses;      //被选中的人
        string g;               //曲线
        string h;               //公钥
        string td;              //陷门
        bool end;               //交易是否结束
    }

    //交易参与者 用于记录是否提交数据
    struct txParticipant
    {
        bool isSubmit;          //是否提交数据
        string data;           //数据
        uint256 len;            //密文长度
        uint256 timeStamp;      //提交时间
    }

    //用于为第三方记录传输数据的信息
    struct dataLock
    {
        uint256 txId;           //交易id
        address consumer;       //数据购买者地址
        uint256[] sites;        //位置
        string[] datas;         //数据
        uint256[] lens;         //长度
        uint256 locked;         //锁
    }

    ///////////////////////////////////////////////////////////////
    /// 事件
    //////////////////////////////////////////////////////////////
    //数据拥有者加入(地址，价值，隐私等级)
    event DataOwnerJoin(address ownerAddr, uint256 value, uint256 privacy);
    //数据拥有者提交数据(地址，交易id)
    event Submit(address ownerAddr, uint256 txId);
    //数据拥有者提钱(地址，金额)
    event Withdraw(address ownerAddr, uint256 balance);

    //数据消费者加入(地址，预算，隐私等级，加入次数）
    event DataConsumerJoin(address consumerAddr, uint256 budget, uint256 privacy, uint256 times);
    //消费者队列入队(队尾,预算，手续费)
    event ConsumerLocked(uint256 LockNum, uint256 budget, uint256 fee);

    //消费者队列出队，上锁(队头，现在的数据拥有者个数)
    event TXLokced(uint256 UnlockedNum, uint256 dataownerNum);

    //无法生成交易，退钱(地址，预算)
    event UnTX(address consumerAddr, uint256 budget);
    //生成交易(地址，交易号，截止时间，预算，剩余，价值)
    event TX(address consumerAddr, uint256 TxId, uint256 deadline, uint256 budget, uint256 residual, uint256 value);

    //处理交易(交易号，超时人数）
    event ProcessTX(uint256 TxId, uint256 TimeoutNum);

    //交易强制结束
    event TXDead(uint256 TxId, address consumerAddr, uint256 budget);

    ///////////////////////////////////////////////////////////////
    /// 映射
    //////////////////////////////////////////////////////////////
    //是否是数据拥有者
    mapping(address => bool) public isDataOwner;
    //是否是数据购买者
    mapping(address => bool) public isDataConsumer; 
    //记录对应地址的数据拥有者信息
    mapping(address => dataOwner) private DataOwner_info;
    //数组对应位置的数据拥有者地址
    mapping(uint256 => address) private dataOwnerAddr;
    //记录对应地址的数据购买者信息
    mapping(address => dataConsumer) private DataConsumer_info;
    //记录对应的交易
    mapping(uint256 => transaction) private tx_info;
    //黑名单
    mapping(address => bool) public blacklist;
    //记录交易id和用户地址对应的交易拥有者是否提交数据
    mapping(uint256 => mapping(address => txParticipant)) public txPar_info;
    //数据对应位置的数据购买者是否在该交易id中
    mapping(uint256 => mapping(uint256 => bool)) private isInTx;
    //第几把锁对应的锁信息
    mapping(uint256 => dataLock) private lockedData;
    //交易锁
    mapping(uint256 => txLocked) private lockedTX;
    
    ///////////////////////////////////////////////////////////////
    /// 修饰器
    ///////////////////////////////////////////////////////////////
    modifier onlyOwner(){
        require(msg.sender == owner,"permission denied");
        _;
    }

    ///////////////////////////////////////////////////////////////
    /// 函数
    ///////////////////////////////////////////////////////////////
    //构造函数
    constructor(uint256 _fee)
    {
        owner = msg.sender;
        Fee = _fee;                     //0.5eth
        fee = _fee;                     //0.5eth
        digit = _fee / 50;             //0.01eth
    }

//////////////////////////////////////////////////////////////////////////////
/// 数据拥有者
////////////////////////////////////////////////////////////////////////////

    //数据拥有者加入
    function dataOwnerJoin(uint privacy) public payable{
        //参与者不能是合约
        require(tx.origin == msg.sender, "A participant cannot be a contract");
        //选择的隐私等级是否合法
        require(privacy >= 1 && privacy <= 5,"illegal privacy level");
        //不能是第三方机构
        require(msg.sender != owner,"Third-party organizations are prohibited from becoming data owners");
        //不能二次加入
        require(isDataOwner[msg.sender] == false,"Do not rejoin");
        //购买队列不在出队中
        require(packageLock == 0,"The intermediary is processing the purchase queue, please wait");
        //不能是数据购买者
        require(isDataConsumer[msg.sender] == false,"Data consumers are prohibited from becoming data owners");
        //数据价值>0.001ETH
        //根据选择的隐私等级计算weight
        uint256 _value = msg.value;
        uint256 tempValue;
        if(privacy == 1){
            tempValue = _value;
        }else if(privacy == 2){
            tempValue = _value * 8 / 10;
        }else if(privacy == 3){
            tempValue = _value * 6 / 10;
        }else if(privacy == 4){
            tempValue = _value * 4 / 10;
        }else if(privacy == 5) {
            tempValue = _value * 2 / 10;
        }
        tempValue = tempValue / digit;
        uint256 tempWeight = _value / digit;
        require(tempValue > 0,"Not enough data value");

        //加入数据拥有者
        isDataOwner[msg.sender] = true;
        ///输入数据拥有者信息
        //数据所有者的地址
        DataOwner_info[msg.sender].ownerAddr = msg.sender;
        //数据价值（价值*隐私）
        DataOwner_info[msg.sender].value = tempValue;
        //隐私等级
        DataOwner_info[msg.sender].privacy = privacy; 
        //数据代价 每次加入可以收到的钱
        DataOwner_info[msg.sender].weight = tempWeight;
        //在数组中的位置
        DataOwner_info[msg.sender].site = dataOwnerNum;
        dataOwnerAddr[dataOwnerNum] = msg.sender;
        dataOwnerNum++;

        //背包入库
        values.push(tempValue);
        weights.push(tempWeight);

        //释放事件
        emit DataOwnerJoin(msg.sender, _value, privacy);
    } 

    //数据拥有者查看自己是否被选中和数据提交剩余时间
    function isChoosed() public view returns(uint256, uint256[] memory, uint256[] memory){
        //是否是数据拥有者
        require(isDataOwner[msg.sender] == true,"not the data owner");
        uint256 flag;
        uint256 time = block.timestamp;
        uint256 site = DataOwner_info[msg.sender].site;
        //查看有几个被选中的
        for(uint256 i = 1; i <= txID; i++){
            //交易未完成&还未到截止时间&被选中
            if(tx_info[i].end == false && tx_info[i].deadline >= time && isInTx[i][site] == true){
                flag++;
            }
        }
        //创建临时数组
        uint256[] memory _txId = new uint256[](flag);
        uint256[] memory _remainingTime = new uint256[](flag);
        uint256 j = 0;
        for(uint256 i = 1; i <= txID; i++){
            if(tx_info[i].end == false && tx_info[i].deadline >= time && isInTx[i][site] == true){
                _txId[j] = i;
                if(tx_info[txID].ownerLine > time){
                    _remainingTime[j] = tx_info[i].ownerLine - time;
                }else {
                    _remainingTime[j] = tx_info[i].deadline - time;
                }
                j++;
            }
        }
        return (flag, _txId, _remainingTime);
    }

    //数据拥有者查看对应交易的公钥和陷门
    function GandTD(uint256 _txId) public view returns(string memory, string memory, string memory){
        //是否是数据拥有者
        require(isDataOwner[msg.sender] == true,"not the data owner");
        //交易号合理
        require(_txId <= txID,"Illegal transaction number");
        //是否在这个交易中
        uint256 site = DataOwner_info[msg.sender].site;
        require(isInTx[_txId][site] == true,"Not in this transaction");

        string memory _g = tx_info[_txId].g;
        string memory _h = tx_info[_txId].h;
        string memory _td = tx_info[_txId].td;

        return (_g,_h,_td);
    }

    //提交数据
    function submit(string memory _data, uint256 _len, uint256 _txId) public {
        //是否是数据拥有者
        require(isDataOwner[msg.sender] == true,"not the data owner");
        //交易号合理
        require(_txId <= txID,"Illegal transaction number");
        //是否在这个交易中
        uint256 site = DataOwner_info[msg.sender].site;
        require(isInTx[_txId][site] == true,"Not in this transaction");
        //是否已经提交过
        require(txPar_info[_txId][msg.sender].isSubmit == false,"Prohibit duplicate submissions");

        //提交
        txPar_info[_txId][msg.sender].isSubmit = true;
        txPar_info[_txId][msg.sender].data = _data;
        txPar_info[_txId][msg.sender].len = _len;
        txPar_info[_txId][msg.sender].timeStamp = block.timestamp;

        emit Submit(msg.sender, _txId);
    }

    //数据拥有者提钱
    function withdraw() public payable {
        //是否是数据拥有者
        require(isDataOwner[msg.sender] == true,"not the data owner");
        //是否在黑名单中
        require(blacklist[msg.sender] == false,"Cannot withdraw money from the blacklist");
        uint256 balance = DataOwner_info[msg.sender].release;
        //是否有钱可提
        require(balance > 0, "no pay to mention");
        DataOwner_info[msg.sender].release = 0;
        payable(msg.sender).transfer(balance);

        emit Withdraw(msg.sender, balance);
    }

////////////////////////////////////////////////////////////////////////
//// 数据消费者
////////////////////////////////////////////////////////////////////

    //数据购买者加入 购买队列 入队
    function dataConsumerJoin(string memory _g, string memory _h, string memory _td, uint256 privacy) public payable {
        //参与者不能是合约
        require(tx.origin == msg.sender, "A participant cannot be a contract");
        //不是三方机构
        require(msg.sender != owner,"Third-party organizations are prohibited from becoming data owners");
        //不是数据拥有者
        require(isDataOwner[msg.sender] == false,"Data owners are prohibited from becoming data consumers");
        //上次交易完成
        if(isDataConsumer[msg.sender] == true){
            require(DataConsumer_info[msg.sender].lastTX == true,"The last transaction has not ended yet");
        }
        //选择的隐私等级是否合法
        require(privacy >= 1 && privacy <= 5,"illegal privacy level");
        uint256 times = DataConsumer_info[msg.sender].times;
        times++;
        uint256 _fee;
        if(privacy == 1){
            _fee = times * 10 / 10 * ( Fee + fee );
        }else if(privacy == 2){
            _fee = times * 8 / 10 * ( Fee + fee );
        }else if(privacy == 3){
            _fee = times * 6 / 10 * ( Fee + fee );
        }else if(privacy == 4){
            _fee = times * 4 / 10 * ( Fee + fee );
        }else if(privacy == 5) {
            _fee = times * 2 / 10 * ( Fee + fee );
        }
        //预算足够付手续费
        require(msg.value >= _fee,"Not enough to pay the fee");
        //加入数据购买者
        isDataConsumer[msg.sender] = true;
        //输入数据购买者信息
        DataConsumer_info[msg.sender].ConsumerAddr = msg.sender;
        DataConsumer_info[msg.sender].Budget = msg.value;
        DataConsumer_info[msg.sender].txLock = txLock;
        DataConsumer_info[msg.sender].lastTX = false;
        DataConsumer_info[msg.sender].privacy = privacy;
        DataConsumer_info[msg.sender].times = times;
        //购买队列入队
        lockedTX[txLock].consumer = msg.sender;
        lockedTX[txLock].budget = msg.value;
        lockedTX[txLock].fee = _fee;
        lockedTX[txLock].g = _g;
        lockedTX[txLock].h = _h;
        lockedTX[txLock].td = _td;
        txLock++;

        emit DataConsumerJoin(msg.sender, msg.value, privacy, times);
        emit ConsumerLocked(txLock-1, msg.value, _fee);
    }

    //数据购买者查看数据
    function getData() public view returns(string memory){
        //该地址为数据购买者
        require(isDataConsumer[msg.sender] == true,"not the data consumer");
        //上次交易完成
        require(DataConsumer_info[msg.sender].lastTX == true,"The last transaction has not ended yet");
        string memory data = DataConsumer_info[msg.sender].data;
        return data;
    }

///////////////////////////////////////////////////////////////////////
//// 中间机构
//////////////////////////////////////////////////////////////////////////

    //查看购买队列 上背包问题锁
    function TXLock() public onlyOwner returns(uint256, uint256){
        require(txLock > txUnlock,"No pending purchases");
        packageLock = 1;
        uint256 _dataOwnerNum = dataOwnerNum;
        //扣除手续费
        uint256 value = lockedTX[txUnlock].budget - lockedTX[txUnlock].fee;
        uint256 _budget = value / digit;
        
        return(_dataOwnerNum, _budget);

        emit TXLokced(txUnlock, _dataOwnerNum);
    }

    function getValues() public view onlyOwner returns(uint256[] memory){
        require(packageLock == 1,"Purchase queue not out of queue");
        uint256[] memory _value = new uint256[](dataOwnerNum);
        address _consumer = lockedTX[txUnlock].consumer;
        uint256 _consumerPrivacy = DataConsumer_info[_consumer].privacy;
        for(uint256 i = 0; i < dataOwnerNum; i++){
            address _owner = dataOwnerAddr[i];
            uint256 _ownerPrivacy = DataOwner_info[_owner].privacy;
            if(_ownerPrivacy <= _consumerPrivacy){
                _value[i] = values[i];
            }else{
                _value[i] = 0;
            }
        }
        return _value;
    }

    function getWeights() public view onlyOwner returns(uint256[] memory){
        require(packageLock == 1,"Purchase queue not out of queue");
        uint256[] memory _weights = new uint256[](dataOwnerNum);
        address _consumer = lockedTX[txUnlock].consumer;
        uint256 _consumerPrivacy = DataConsumer_info[_consumer].privacy;
        for(uint256 i = 0; i < dataOwnerNum; i++){
            address _owner = dataOwnerAddr[i];
            uint256 _ownerPrivacy = DataOwner_info[_owner].privacy;
            if(_ownerPrivacy <= _consumerPrivacy){
                _weights[i] = weights[i];
            }else{
                _weights[i] = 0;
            }
        }
        return _weights;
    }

    //购买队列 出队 解背包问题锁
    function txGenerate(uint256 _dataValue, uint256[] memory _choose, uint256 _txOwnerNum, uint256 _residue) public onlyOwner returns(uint256){
        //队列中有购买者
        require(txLock > txUnlock,"No pending purchases");
        //数据无误
        require(_choose.length == dataOwnerNum && _txOwnerNum <= dataOwnerNum, "The submitted data is incorrect");
        //解锁
        packageLock = 0;
        uint256 value = lockedTX[txUnlock].budget;
        uint256 _fee = lockedTX[txUnlock].fee / 2;
        uint256 _budget = ( value - lockedTX[txUnlock].fee ) / digit;
        //买不到数据，退钱
        if(_dataValue == 0){
            txUnlock++;
            payable(lockedTX[txUnlock].consumer).transfer(value);
            DataConsumer_info[lockedTX[txUnlock].consumer].lastTX = true;
            txUnlock++;
            emit UnTX(lockedTX[txUnlock].consumer, value);
            return 0;
        }
        
        //生成交易
        for(uint256 i = 0; i < dataOwnerNum; i++){
            if(_choose[i] == 1){
               isInTx[txID+1][i] = true;
            }
        }

        _dataValue = _dataValue * digit;
        _residue = value - _fee * 2 - _residue * digit;
        txID++;
        //输入交易信息
        tx_info[txID] = transaction({
            consumer : lockedTX[txUnlock].consumer,
            startTime : block.timestamp,
            ownerLine : block.timestamp, //+ 7200,
            deadline : block.timestamp, //+ 36000,
            budget : _budget,
            value : _dataValue,
            residual : _residue,
            fee : _fee,
            txOwnerNum : _txOwnerNum,
            chooses : _choose,
            g : lockedTX[txUnlock].g,
            h : lockedTX[txUnlock].h,
            td : lockedTX[txUnlock].td,
            end : false
        });
        txUnlock++; 
        emit TX(lockedTX[txUnlock].consumer, txID, block.timestamp + 36000, _budget, _residue, _dataValue);
        return 1;
    }

    //第三方机构查询还未到强制结束时间的交易  返回交易id和强制结束时间的数组
    function unprocessedTX() public view onlyOwner returns(uint256, uint256[] memory, uint256[] memory){
        uint256 flag;
        uint256 time = block.timestamp;
        for(uint256 i = 1; i <= txID; i++){
            //交易未完成&过了可操作时间&还未到截止时间
            if(tx_info[i].end == false && tx_info[i].ownerLine <= time && tx_info[i].deadline >= time){
               flag++;
            }
        }
        //创建临时数组
        uint256[] memory _txId = new uint256[](flag);
        uint256[] memory _deadline = new uint256[](flag);
        uint256 j = 0;
        for(uint256 i = 1; i <= txID; i++){
            //交易未完成&过了可操作时间&还未到截止时间
            if(tx_info[i].end == false && tx_info[i].ownerLine <= time && tx_info[i].deadline >= time){
                _txId[j] = i;
                _deadline[j] = tx_info[i].deadline;
                j++;
            }
        }
        return (flag, _txId, _deadline);
    }

/////////////////////////////////////////////////////////////
///处理交易

    //返回还未提交数据的用户个数
    function _timeoutNum(uint256 _txId) private view onlyOwner returns(uint256 num) {
        address _ownerAddr;
        for(uint256 i = 0; i < dataOwnerNum; i++){
            if(tx_info[_txId].chooses[i] == 1){
                _ownerAddr = dataOwnerAddr[i];
                if(txPar_info[_txId][_ownerAddr].isSubmit == false){
                    num++;
                }
            }
        }
    }


    //记录超时 踢出超时者
    function _timeout(uint256 _txId) private {
        address _ownerAddr;
        for(uint256 i = 0; i < dataOwnerNum; i++){
            if(tx_info[_txId].chooses[i] == 1){
                _ownerAddr = dataOwnerAddr[i];
                if(txPar_info[_txId][_ownerAddr].isSubmit == false){
                    DataOwner_info[_ownerAddr].times++;
                    tx_info[_txId].txOwnerNum--;
                    tx_info[_txId].residual+= DataOwner_info[_ownerAddr].weight;
                    tx_info[_txId].value-= DataOwner_info[_ownerAddr].value;
                    tx_info[_txId].chooses[i] = 0;
                    txPar_info[_txId][_ownerAddr].isSubmit = true;
                }
            }
        }
    }

    //处理黑名单
    function dealBlacklist(uint256 _txId) public payable{
        address _ownerAddr;
        address _consumer = tx_info[_txId].consumer;
        for(uint256 i = 0; i < dataOwnerNum; i++){
            _ownerAddr = dataOwnerAddr[i];
            if(DataOwner_info[_ownerAddr].times > 3 && blacklist[_ownerAddr] == false){
                blacklist[_ownerAddr] = true;
                payable(_consumer).transfer(DataOwner_info[_ownerAddr].weight * digit);
                values[i] = 0;
                weights[i] = 0;
            }
        }
    }

    //分钱
    function _release(uint256 _txId) private onlyOwner{
        address _ownerAddr; 
        //剩余的钱
        uint256 externalFee = tx_info[_txId].residual / tx_info[_txId].txOwnerNum;
        //隐私补偿
        uint256 _fee = tx_info[_txId].fee; 
        uint256 allWeight;
        for(uint256 i = 0; i < dataOwnerNum; i++){
            allWeight = allWeight + weights[i];
        }
        for(uint256 i = 0; i < dataOwnerNum; i++){
            _ownerAddr = dataOwnerAddr[i];
            if(tx_info[_txId].chooses[i] == 1){
                DataOwner_info[_ownerAddr].release = DataOwner_info[_ownerAddr].release + DataOwner_info[_ownerAddr].weight + externalFee;
            }
            DataOwner_info[_ownerAddr].release = DataOwner_info[_ownerAddr].release + _fee * weights[i] / allWeight;
        }
    }

    //获得数据
    function dataSum(uint256 _txId) public view onlyOwner returns(uint256[] memory, string[] memory, uint256[] memory) {
        address _ownerAddr;
        uint256 flag;
        for(uint256 i = 0; i < dataOwnerNum; i++){
            if(tx_info[_txId].chooses[i] == 1){
                _ownerAddr = dataOwnerAddr[i];
                if(txPar_info[_txId][_ownerAddr].isSubmit == true){
                    flag++;
                }
            }
        }

        //创建临时数组
        uint256[] memory _sites = new uint256[](flag);
        uint256[] memory _lens = new uint256[](flag);
        string[] memory _datas = new string[](flag);
        uint256 j = 0;

        for(uint256 i = 0; i < dataOwnerNum; i++){
            if(tx_info[_txId].chooses[i] == 1){
                _ownerAddr = dataOwnerAddr[i];
                if(txPar_info[_txId][_ownerAddr].isSubmit == true){
                    _sites[j] = i;
                    _datas[j] = txPar_info[_txId][_ownerAddr].data;
                    _lens[j] = txPar_info[_txId][_ownerAddr].len;
                    j++;
                }
            }
        }
        return (_sites, _datas, _lens);
    }

    //处理交易
    function processTX(uint256 _txId) public onlyOwner{
        //是否被上锁
        require(lockedData[lock].locked == 0,"The last data transfer has not been completed yet");
        //交易是否结束
        require(tx_info[_txId].end == false, "transaction has ended");
        //交易是否可以处理
        require(tx_info[_txId].ownerLine <= block.timestamp, "The transaction has not yet been executed");
        //交易是否强制处理了
        require(tx_info[_txId].deadline >= block.timestamp, "transaction has ended");
        //还未提交数据的用户个数
        uint256 timeoutN = _timeoutNum(_txId);
        uint256 mustN = tx_info[_txId].txOwnerNum / 20;
        //提交数据的用户足够多
        require(timeoutN <= mustN,"Too many users who have not submitted data");
        //记录超时 踢出超时者
        _timeout(_txId);
        //处理黑名单
        dealBlacklist(_txId);
        //分钱
        _release(_txId);
        //交易结束
        tx_info[_txId].end = true;
        DataConsumer_info[tx_info[_txId].consumer].lastTX = true;
        //获得数据
        (uint256[] memory _sites,string[] memory _datas, uint256[] memory _lens) = dataSum(_txId);
        //上锁
        lockedData[lock] = dataLock({
            txId : _txId,
            consumer : tx_info[_txId].consumer,
            sites : _sites,
            datas : _datas,
            lens : _lens,
            locked : 1
        });
        
        emit ProcessTX(_txId, timeoutN);
    }

    //查看锁信息
    function lockInformation() public view onlyOwner returns(dataLock memory a){
        a = lockedData[lock];
    }

    //传输数据 解锁
    function dataTransmission(address _consumer, string calldata _data, uint256 _len) public onlyOwner{
        DataConsumer_info[_consumer].lastTX = true;
        DataConsumer_info[_consumer].data = _data;
        DataConsumer_info[_consumer].len = _len;
        lockedData[lock].locked = 0;
        lock++;
    }

///处理交易
//////////////////////////////////////////////////////////////////////////////////

    //第三方获得某次交易未提交数据的数据所有者地址
    function unSubmitAddr(uint256 _txId) public view onlyOwner returns(address[] memory){
        //交易还未结束
        require(tx_info[txID].end == false,"The transaction has ended");
        address _ownerAddr;
        uint256 num;
        for(uint256 i = 0; i < dataOwnerNum; i++){
            if(tx_info[_txId].chooses[i] == 1){
                _ownerAddr = dataOwnerAddr[i];
                if(txPar_info[_txId][_ownerAddr].isSubmit == false){
                    num++;
                }
            }
        }
        address[] memory unSubAddr = new address[](num);
        uint256 j = 0;
        for(uint256 i = 0; i < dataOwnerNum; i++){
            if(tx_info[_txId].chooses[i] == 1){
                _ownerAddr = dataOwnerAddr[i];
                if(txPar_info[_txId][_ownerAddr].isSubmit == false){
                    unSubAddr[j] = _ownerAddr;
                }
            }
        }
        return unSubAddr;
    }

    //查看数据拥有者资料(只有第三方能做)
    function dataOwnerProfile(address _addr) public view onlyOwner returns (dataOwner memory){
        //该地址为数据拥有者
        require(isDataOwner[_addr] == true,"not the data owner");
        return DataOwner_info[_addr];
    }

    //查看数据购买者资料(只有第三方能做)
    function dataConsumerProfile(address _addr) public view onlyOwner returns (dataConsumer memory){
        //该地址为数据购买者
        require(isDataConsumer[_addr] == true,"not the data consumer");
        return DataConsumer_info[_addr];
    }

    //查看交易信息(只有第三方能做)
    function txProfile(uint256 _txId) public view onlyOwner returns (transaction memory){
        return tx_info[_txId];
    }

///////////////////////////////////////////////////////////////////////////////
//// 脚本运行
///////////////////////////////////////////////////////////////////////////////

    function txDead() public payable{
        //不能是第三方机构
        require(msg.sender != owner,"Third-party organizations are prohibited from becoming data owners");
        //不能是数据购买者
        require(isDataConsumer[msg.sender] == false,"Data consumers are prohibited from becoming data owners");
        //不是数据拥有者
        require(isDataOwner[msg.sender] == false,"Data owners are prohibited from becoming data consumers");
        uint256 time = block.timestamp;
        for(uint256 i = 1; i <= txID; i++){
            //交易未完成&过了截止时间
            if(tx_info[i].end == false && tx_info[i].deadline <= time){
               //记录超时 踢出超时者
                _timeout(i);
                //处理黑名单
                dealBlacklist(i);
                //退钱
                address consumer = tx_info[i].consumer;
                payable(consumer).transfer(DataConsumer_info[consumer].Budget);
                //交易结束
                DataConsumer_info[consumer].lastTX = true;
                tx_info[i].end = true;

                emit TXDead(i, consumer, DataConsumer_info[consumer].Budget);
            }
        }
    }

    fallback() external payable {}

    receive() external payable {}
}


