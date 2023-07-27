use core::clone::Clone;
use serde::Serde;
use array::ArrayTrait;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use result::ResultTrait;
use debug::PrintTrait;

use erc721::token::erc721::{IERC721};
use erc721::token::erc721::{IERC721Dispatcher, IERC721DispatcherTrait, ERC721};
use starknet::{get_contract_address, get_caller_address, deploy_syscall, ClassHash, contract_address_const, ContractAddress};

fn deploy(name: felt252, symbol: felt252) -> (ContractAddress, IERC721Dispatcher) {
    let mut constructor_args: Array<felt252> = ArrayTrait::<felt252>::new();
    Serde::serialize(@name, ref constructor_args);
    Serde::serialize(@symbol, ref constructor_args);

    let account: ContractAddress = contract_address_const::<1>();
    //let (erc721_addr, _) = deploy_syscall(ERC721::TEST_CLASS_HASH.try_into().unwrap(), 0, ArrayTrait::<felt252>::new().span(), false).unwrap();
    let (erc721_addr, _) = deploy_syscall(ERC721::TEST_CLASS_HASH.try_into().unwrap(), 0, constructor_args.span(), false).unwrap();
    
    (account, IERC721Dispatcher { contract_address: erc721_addr })
}

fn set_caller_as_zero() {
    starknet::testing::set_contract_address(contract_address_const::<0>());
}

#[test]
#[available_gas(3000000)]
fn test_set_token_uri() {

    let (owner, collection) = deploy('NFT', 'NFT');

    starknet::testing::set_contract_address(owner);
    collection.mint(get_contract_address(), 0_u256);
    'After Mint!'.print();

    assert(collection.balance_of(get_contract_address()) == 1_u256, 'balance_of');
    'After balance_of!'.print();
    assert(collection.ownerOf(0_u256) == get_contract_address(), 'owner_of');

    let mut token_uri: Array<felt252> = ArrayTrait::new();
    token_uri.append('https://gateway.pinata.cloud/ip');
    token_uri.append('fs/XXXXXXXXXXXXXXXXXXXXXXXXXXX/');
    let token_uri_len: felt252 = 2;
    let token_uri_suffix: felt252 = '.json';

    assert(token_uri.at(0).into().clone() == 'https://gateway.pinata.cloud/ip', 'token_uri.at(0)');

    collection.setBaseURI(token_uri_len, token_uri, token_uri_suffix);
    'After X!'.print();

    let (token_uri_len, token_urib) = collection.tokenURI(0_u256);
    assert(token_uri_len == 2, 'token_uri_len == 2');

    // Need to reorganize the array
    assert(token_urib.at(1).into().clone() == 'fs/XXXXXXXXXXXXXXXXXXXXXXXXXXX/', 'token_uri.at(0)');
    assert(token_urib.at(0).into().clone() == 'https://gateway.pinata.cloud/ip', 'token_uri.at(1)');
    assert(token_urib.at(2).into().clone() == 0, 'token_uri.at(2)');
    assert(token_urib.at(3).into().clone() == '.json', 'token_uri.at(3)');

}

