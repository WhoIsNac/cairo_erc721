use core::clone::Clone;
//use core::traits::Into;
use starknet::ContractAddress;




#[starknet::interface] //question @
trait IERC721<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    //fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, id: u256) -> bool;
    fn transfer_from(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, id: u256) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, id: u256) -> bool;
    fn mint(ref self: TContractState, recipient: ContractAddress, id: u256);
    fn burn(ref self: TContractState, account: ContractAddress, id: u256);
    // fn token_approval(ref self: @TContractState, spender: ContractAddress, id: u256) -> bool;
    // fn setApprovalForAll(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> bool;
    // fn baseURI(ref self: @TContractState) -> felt252;
    fn getApproved(self: @TContractState, id: u256) -> ContractAddress;
    //isApprovedForAll ET 
    fn setApprovalForAll(ref self: TContractState, owner: ContractAddress, spender: ContractAddress,operator: bool) -> bool;
    fn isApprovedForAll(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> bool;
    //fn exist(self: @TContractState,id:u256) -> bool;
    fn ownerOf(self: @TContractState,id:u256) -> ContractAddress;
    fn tokenURI(self: @TContractState, id: u256) -> (felt252,Array::<felt252>);
    fn setBaseURI(ref self: TContractState, uri_len:felt252,uri: Array::<felt252>,suffixe:felt252);
   // fn convert_to_felt(self: @TContractState, id: u8);

}

#[starknet::contract]
mod ERC721 {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;
    use integer::BoundedInt;
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;
    //use debug::PrintTrait;
    use array::ArrayTrait;
    use clone::Clone;
    



    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252) {
        self.initializer(name, symbol);
    }

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        total_supply: u256,
        baseURI: felt252,
        tokenURI_suffixe: felt252,
        burnAddr:ContractAddress,
        balances: LegacyMap<ContractAddress, u256>,
        //allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        tokenApprovals:LegacyMap<u256,ContractAddress>, //question à poser
        operatorApprovals: LegacyMap<(ContractAddress, ContractAddress), bool>,
        owners:LegacyMap<u256,ContractAddress>, //question à poser
        //token_uri:Array::<felt252>, //bug de merde ne compilepas
        token_uri2:LegacyMap::<felt252,felt252>, // question double point à poser 
        uri_len:felt252,
    }

    #[event]
    #[derive(Drop,Destruct, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress, 
        to: ContractAddress, 
        id: u256
    }

     #[derive(Copy, Drop)]
    enum token_uriStruct {
        prefix: felt252,
        base: felt252,
        id: felt252,
        suffixe: felt252,
    }
    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress, 
        spender: ContractAddress, 
        value: u256
    }
    

    #[external(v0)]
    impl ERC721Impl of super::IERC721<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn decimals(self: @ContractState) -> u8 {
            1_u8
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }

        // fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
        //     self.allowances.read((owner, spender))
        // }

        fn getApproved(self: @ContractState,  id: u256) -> ContractAddress {
             self.tokenApprovals.read(id)
         }

         fn ownerOf(self: @ContractState,  id: u256) -> ContractAddress {
             self.owners.read(id)
         }

        fn transfer(ref self: ContractState, recipient: ContractAddress, id: u256) -> bool {
            let sender = get_caller_address();
            assert(self.owners.read(id) != sender, 'ERC720: not the owner');
            self.transfer(sender, recipient, id);
            true
        }

        fn transfer_from(ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, id: u256) -> bool {
            let caller = get_caller_address();
            assert(self.owners.read(id) != sender, 'ERC720: not the owner');
            
            assert(!self.operatorApprovals.read((sender, recipient)), 'ERC720: not the owner');
            assert(self.tokenApprovals.read(id) != recipient , 'ERC720: not approved');

            //self.spend_allowance(sender, caller, id);
            self.transfer(sender, recipient, id);
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, id: u256) -> bool {
            let caller = get_caller_address();
            self.approve(caller, spender, id);
            true
        }

        fn mint(ref self: ContractState, recipient: ContractAddress, id: u256) {
            self.mint(recipient, id)
        }

        fn burn(ref self: ContractState, account: ContractAddress, id: u256) {
            let caller = get_caller_address();
            self.delete_allowance(account, caller, id);
            self.burn(account, id)
        }

        fn setApprovalForAll(ref self: ContractState, owner: ContractAddress, spender: ContractAddress, operator: bool) -> bool {
            self.setApprovalForAll(spender,operator)
        }
        
        fn isApprovedForAll(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> bool {
            self.operatorApprovals.read((owner, spender))
        }


        fn tokenURI(self: @ContractState, id: u256) -> (felt252,Array::<felt252>) {
            let baseURI = self.baseURI.read();
            let mut token_uriRet: Array<felt252> = ArrayTrait::new();
            let mut uri_length = self.uri_len.read();
            self.tokenURI(uri_length,ref token_uriRet);
            token_uriRet.append(id.try_into().unwrap());
            token_uriRet.append(self.tokenURI_suffixe.read());
            // return token_uriRet;
            (uri_length,token_uriRet)
            // let test: felt252 = id.into();
            //let uri = self.token_uri2.read()
            // //let my_other_felt252: felt252 = id.into();

            // test with only felt256 but char exced the max size of an felt
            // let idString = id.try_into().unwrap();
            // baseURI + idString;
            //"http//azpeazpepazeipaezip/Id.json"
        }

        fn setBaseURI(ref self: ContractState,uri_len:felt252, uri:Array::<felt252>, suffixe:felt252) {
            let mut token_uri: Array<felt252> = ArrayTrait::new();
            // token_uri.append((prefix));
            // token_uri.append(uri);
            //self.tokenURI_suffixe.write(suffixe);
            self.tokenURI_suffixe.write(suffixe);
            self.uri_len.write(uri_len);

            self.setBaseURI(uri_len,uri);

            
            //token_uri.append(token_uriStruct::suffixe(suffixe));
            //self.token_uri = uri_struct.span();
            //self.token_uri.read() = uri_struct.clone();
            //self.token_uri.append(token_uriStruct::prefix(prefix));
        }

        // fn convert_to_felt(self: @ContractState,id: u8) {
        //     //let s = self.0
        //     //let serialized = serde_json::to_string(id).unwrap();
        //     //let bytes = vec![0x41, 0x42, 0x43];
        //     //let s = format!("{:?}", &bytes);
        //         //id.try_into().unwrap()
        // }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn initializer(ref self: ContractState, name: felt252, symbol: felt252) {
            self.name.write(name);
            self.symbol.write(symbol);
        }

        fn mint(ref self: ContractState, recipient: ContractAddress, id: u256) {
            assert(!recipient.is_zero(), 'ERC20: mint to 0');
            assert(self.owners.read(id) != recipient, 'ERC720: id already exist');

            self.total_supply.write(self.total_supply.read() + 1);
            self.owners.write(id,recipient);

            self.balances.write(recipient, self.balances.read(recipient) + 1);
            self.emit(Event::Transfer(Transfer { from: Zeroable::zero(), to: recipient, id: id }));
        }
        

        fn burn(ref self: ContractState, account: ContractAddress, id: u256) {
            assert(!account.is_zero(), 'ERC20: burn from 0');

            self.owners.write(id,Zeroable::zero());

            self.total_supply.write(self.total_supply.read() - 1);
            self.balances.write(account, self.balances.read(account) - 1);
            self.emit(Event::Transfer(Transfer { from: account, to: Zeroable::zero(), id: id }));
        }

        fn approve(ref self: ContractState, owner: ContractAddress, spender: ContractAddress, id: u256) {
            assert(!owner.is_zero(), 'ERC20: approve from 0');
            assert(!spender.is_zero(), 'ERC20: approve to 0');
            //self.allowances.write(id, ContractAddress);
            self.tokenApprovals.write(id,(spender));
           // self.emit(Event::Approval(Approval { owner, spender, value: amount })); //à modif
        }

        fn transfer(ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, id: u256) {
            assert(!sender.is_zero(), 'ERC720: transfer from 0');
            assert(!recipient.is_zero(), 'ERC720: transfer to 0');
            assert(self.owners.read(id) != sender, 'ERC720: not the owner');

            self.owners.write(id,recipient);
            self.balances.write(sender, self.balances.read(sender) - 1);
            self.balances.write(recipient, self.balances.read(recipient) + 1);
            
            self.emit(Event::Transfer(Transfer { from: sender, to: recipient, id: id }));
        }
        
        fn delete_allowance(ref self: ContractState, owner: ContractAddress, spender: ContractAddress, id: u256) {
            assert(!owner.is_zero(), 'ERC20: approve from 0');
            assert(!spender.is_zero(), 'ERC20: approve to 0');
            //self.allowances.write(id, ContractAddress);
            self.tokenApprovals.write(id,self.burnAddr.read());
        }

        
         fn setApprovalForAll(ref self: ContractState, spender: ContractAddress,operator: bool) -> bool {
            let caller = get_caller_address();
            self.operatorApprovals.write((caller, spender),operator);
            true
        }

        fn setBaseURI(ref self: ContractState, uri_len:felt252, uri:Array::<felt252>) {
            let urlen2 = self.uri_len.read();
            if uri_len == 0 { return; }
            

            //let urlen = uri_len ;
            //let res = uri_len - urlen2;
            //assert(res.into() == 0,'passed');
            //'print in boucle'.print();
            //self.token_uri2.write(res,*uri.at(res.try_into().unwrap()));
            
            //self.setBaseURI(uri_len + 1,uri);

            //self.token_uri.write(uri.at(0));
           // self.token_uri.write(uri);
            self.token_uri2.write(uri_len -1,*uri.at(uri_len.try_into().unwrap() - 1));
            self.setBaseURI(uri_len - 1,uri);
            //recusrif call 

        }

        
        fn tokenURI(self: @ContractState,uri_length:felt252, ref uri:Array::<felt252>)  {
            let urlen2 = self.uri_len.read();
            if uri_length == urlen2 + urlen2{ return; }
            
            let urlen = uri_length ;
            let res = uri_length - urlen2; 
             
             let content = self.token_uri2.read(res);
            uri.append(content);
            self.tokenURI(uri_length + 1,ref uri);
        }
    }

}