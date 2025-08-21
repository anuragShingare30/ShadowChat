use contract::{
    IHelloStarknetDispatcher, IHelloStarknetDispatcherTrait, IHelloStarknetSafeDispatcher,
    IHelloStarknetSafeDispatcherTrait,
};
use contract::{
    IProfileSystemDispatcher, IProfileSystemDispatcherTrait
};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;
use core::array::ArrayTrait;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_increase_balance() {
    let contract_address = deploy_contract("HelloStarknet");
    let dispatcher = IHelloStarknetDispatcher { contract_address };

    let balance_before = dispatcher.get_balance();
    assert(balance_before == 0, 'Invalid balance');

    dispatcher.increase_balance(42);

    let balance_after = dispatcher.get_balance();
    assert(balance_after == 42, 'Invalid balance');
}

#[test]
#[feature("safe_dispatcher")]
fn test_cannot_increase_balance_with_zero_value() {
    let contract_address = deploy_contract("HelloStarknet");
    let safe_dispatcher = IHelloStarknetSafeDispatcher { contract_address };

    let balance_before = safe_dispatcher.get_balance().unwrap();
    assert(balance_before == 0, 'Invalid balance');

    match safe_dispatcher.increase_balance(0) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
        },
    };
}
// #[test]
// fn test_set_and_get_profile() {
//     let contract_address = deploy_contract("ProfileSystem");

//     let dispatcher = IProfileSystemDispatcher { contract_address };

//     // Set a profile
//     dispatcher.set_profile("user1", "John Doe", "http://example.com/johndoe.jpg");

//     // Retrieve the profile
//     let (name, profile_pic_url) = dispatcher.get_profile("user1");

//     // Assert that the retrieved profile matches the set values
//     assert(name == "John Doe", 'Name should match');
//     assert(profile_pic_url == "http://example.com/johndoe.jpg", 'Profile picture URL should
//     match');
// }

#[test]
fn test_set_and_get_profile() {
    let contract_address = deploy_contract("ProfileSystem");
    let dispatcher = IProfileSystemDispatcher { contract_address };

    // Set a profile - using shorter URL to fit in felt252
    dispatcher.set_profile('user1', 'John Doe', 'example.com/profile.jpg');

    // Retrieve the profile
    let (name, profile_pic_url) = dispatcher.get_profile('user1');

    // Assert that the retrieved profile matches the set values
    assert(name == 'John Doe', 'Name should match');
    assert(profile_pic_url == 'example.com/profile.jpg', 'URL should match');
}

// additional test suite
#[test]
fn test_multiple_balance_increases() {
    let contract_address = deploy_contract("HelloStarknet");
    let dispatcher = IHelloStarknetDispatcher { contract_address };

    // Initial balance should be 0
    let balance = dispatcher.get_balance();
    assert(balance == 0, 'Initial balance should be 0');

    // Multiple increases
    dispatcher.increase_balance(10);
    dispatcher.increase_balance(20);
    dispatcher.increase_balance(30);

    let final_balance = dispatcher.get_balance();
    assert(final_balance == 60, 'Balance should be 60');
}

#[test]
fn test_increase_balance_with_large_value() {
    let contract_address = deploy_contract("HelloStarknet");
    let dispatcher = IHelloStarknetDispatcher { contract_address };

    let large_value = 999999999999999999;
    dispatcher.increase_balance(large_value);

    let balance = dispatcher.get_balance();
    assert(balance == large_value, 'Large value not handled');
}

#[test]
fn test_increase_balance_with_one() {
    let contract_address = deploy_contract("HelloStarknet");
    let dispatcher = IHelloStarknetDispatcher { contract_address };

    dispatcher.increase_balance(1);

    let balance = dispatcher.get_balance();
    assert(balance == 1, 'Balance should be 1');
}

#[test]
fn test_consecutive_balance_operations() {
    let contract_address = deploy_contract("HelloStarknet");
    let dispatcher = IHelloStarknetDispatcher { contract_address };

    // Test consecutive operations
    dispatcher.increase_balance(5);
    let balance1 = dispatcher.get_balance();
    assert(balance1 == 5, 'First increase failed');

    dispatcher.increase_balance(15);
    let balance2 = dispatcher.get_balance();
    assert(balance2 == 20, 'Second increase failed');

    dispatcher.increase_balance(25);
    let balance3 = dispatcher.get_balance();
    assert(balance3 == 45, 'Third increase failed');
}

// Additional ProfileSystem tests for improved coverage

#[test]
fn test_profile_update() {
    let contract_address = deploy_contract("ProfileSystem");
    let dispatcher = IProfileSystemDispatcher { contract_address };

    // Set initial profile
    dispatcher.set_profile('user1', 'John Doe', 'old.jpg');
    let (name, url) = dispatcher.get_profile('user1');
    assert(name == 'John Doe', 'Initial name wrong');
    assert(url == 'old.jpg', 'Initial URL wrong');

    // Update the same profile
    dispatcher.set_profile('user1', 'John Smith', 'new.jpg');
    let (updated_name, updated_url) = dispatcher.get_profile('user1');
    assert(updated_name == 'John Smith', 'Updated name wrong');
    assert(updated_url == 'new.jpg', 'Updated URL wrong');
}

#[test]
fn test_multiple_profiles() {
    let contract_address = deploy_contract("ProfileSystem");
    let dispatcher = IProfileSystemDispatcher { contract_address };

    // Set multiple different profiles
    dispatcher.set_profile('user1', 'Alice', 'alice.jpg');
    dispatcher.set_profile('user2', 'Bob', 'bob.jpg');
    dispatcher.set_profile('user3', 'Charlie', 'charlie.jpg');

    // Verify each profile independently
    let (alice_name, alice_url) = dispatcher.get_profile('user1');
    assert(alice_name == 'Alice', 'Alice name wrong');
    assert(alice_url == 'alice.jpg', 'Alice URL wrong');

    let (bob_name, bob_url) = dispatcher.get_profile('user2');
    assert(bob_name == 'Bob', 'Bob name wrong');
    assert(bob_url == 'bob.jpg', 'Bob URL wrong');

    let (charlie_name, charlie_url) = dispatcher.get_profile('user3');
    assert(charlie_name == 'Charlie', 'Charlie name wrong');
    assert(charlie_url == 'charlie.jpg', 'Charlie URL wrong');
}

#[test]
fn test_get_nonexistent_profile() {
    let contract_address = deploy_contract("ProfileSystem");
    let dispatcher = IProfileSystemDispatcher { contract_address };

    // Try to get a profile that doesn't exist
    let (name, url) = dispatcher.get_profile('nonexistent');
    
    // Should return default values (empty felt252)
    assert(name == 0, 'Nonexistent name should be 0');
    assert(url == 0, 'Nonexistent URL should be 0');
}

#[test]
fn test_profile_with_numeric_username() {
    let contract_address = deploy_contract("ProfileSystem");
    let dispatcher = IProfileSystemDispatcher { contract_address };

    // Use numeric usernames
    dispatcher.set_profile(12345, 'Numeric User', 'num.jpg');
    
    let (name, url) = dispatcher.get_profile(12345);
    assert(name == 'Numeric User', 'Numeric username failed');
    assert(url == 'num.jpg', 'Numeric URL failed');
}

#[test]
fn test_profile_with_zero_values() {
    let contract_address = deploy_contract("ProfileSystem");
    let dispatcher = IProfileSystemDispatcher { contract_address };

    // Test with zero values (should be allowed)
    dispatcher.set_profile(0, 0, 0);
    
    let (name, url) = dispatcher.get_profile(0);
    assert(name == 0, 'Zero name handling failed');
    assert(url == 0, 'Zero URL handling failed');
}

#[test]
fn test_profile_overwrite_behavior() {
    let contract_address = deploy_contract("ProfileSystem");
    let dispatcher = IProfileSystemDispatcher { contract_address };

    // Set profile multiple times with same username
    dispatcher.set_profile('test', 'First', 'first.jpg');
    dispatcher.set_profile('test', 'Second', 'second.jpg');
    dispatcher.set_profile('test', 'Third', 'third.jpg');

    // Should only keep the last one
    let (name, url) = dispatcher.get_profile('test');
    assert(name == 'Third', 'Profile overwrite failed');
    assert(url == 'third.jpg', 'URL overwrite failed');
}

// Cross-contract interaction tests

#[test]
fn test_multiple_contract_instances() {
    // Deploy two separate HelloStarknet contracts
    let contract1 = deploy_contract("HelloStarknet");
    let contract2 = deploy_contract("HelloStarknet");
    
    let dispatcher1 = IHelloStarknetDispatcher { contract_address: contract1 };
    let dispatcher2 = IHelloStarknetDispatcher { contract_address: contract2 };

    // Modify each contract independently
    dispatcher1.increase_balance(100);
    dispatcher2.increase_balance(200);

    // Verify they maintain separate state
    let balance1 = dispatcher1.get_balance();
    let balance2 = dispatcher2.get_balance();
    
    assert(balance1 == 100, 'Contract 1 balance wrong');
    assert(balance2 == 200, 'Contract 2 balance wrong');
}

#[test]
fn test_multiple_profile_contract_instances() {
    // Deploy two separate ProfileSystem contracts
    let contract1 = deploy_contract("ProfileSystem");
    let contract2 = deploy_contract("ProfileSystem");
    
    let dispatcher1 = IProfileSystemDispatcher { contract_address: contract1 };
    let dispatcher2 = IProfileSystemDispatcher { contract_address: contract2 };

    // Set profiles in each contract
    dispatcher1.set_profile('user', 'Contract1 User', 'c1.jpg');
    dispatcher2.set_profile('user', 'Contract2 User', 'c2.jpg');

    // Verify separate state
    let (name1, url1) = dispatcher1.get_profile('user');
    let (name2, url2) = dispatcher2.get_profile('user');
    
    assert(name1 == 'Contract1 User', 'Contract 1 name wrong');
    assert(url1 == 'c1.jpg', 'Contract 1 URL wrong');
    assert(name2 == 'Contract2 User', 'Contract 2 name wrong');
    assert(url2 == 'c2.jpg', 'Contract 2 URL wrong');
}
