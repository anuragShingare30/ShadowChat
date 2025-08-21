
use contract::message::{
    IMessageStorageDispatcher, 
    IMessageStorageDispatcherTrait,
    IMessageStorageSafeDispatcher,
    IMessageStorageSafeDispatcherTrait,
};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use starknet::ContractAddress;
use core::array::ArrayTrait;
use core::traits::TryInto;

// Define a helper function to deploy the contract
fn deploy_contract() -> (IMessageStorageDispatcher, IMessageStorageSafeDispatcher) {
    let contract_class = declare("MessageStorage").unwrap().contract_class();
    let (contract_address, _) = contract_class.deploy(@ArrayTrait::new()).unwrap();

    let message_storage_dispatcher = IMessageStorageDispatcher { contract_address };
    let message_storage_safe_dispatcher = IMessageStorageSafeDispatcher { contract_address };
    
    (message_storage_dispatcher, message_storage_safe_dispatcher)
}

#[test]
fn test_store_and_get_message() {
    // Deploy the contract
    let (message_storage_dispatcher, _) = deploy_contract();

    // Define a recipient address
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    // Define a message
    let message: ByteArray = "Hello, World!";

    // Store the message
    message_storage_dispatcher.store_message(recipient, message.clone());

    // Retrieve the message at index 0
    let retrieved_message = message_storage_dispatcher.get_message(recipient, 0);

    // Assert that the retrieved message matches
    assert(retrieved_message == message, 'Retrieved message should match');
}

#[test]
fn test_get_all_messages() {
    let (message_storage_dispatcher, _) = deploy_contract();

    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    let message1: ByteArray = "Hello, Alice!";
    let message2: ByteArray = "Hello, Bob!";

    message_storage_dispatcher.store_message(recipient, message1.clone());
    message_storage_dispatcher.store_message(recipient, message2.clone());

    let all_messages = message_storage_dispatcher.get_all_messages(recipient);

    assert(all_messages.len() == 2, 'Incorrect number of messages');

    assert(all_messages.at(0) == @message1, 'First message should match');
    assert(all_messages.at(1) == @message2, 'Second message should match');
}

#[test]
#[feature("safe_dispatcher")]
fn test_safe_panic_cannot_store_empty_message() {
    let (_, message_storage_safe_dispatcher) = deploy_contract();

    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    let result = message_storage_safe_dispatcher.store_message(recipient, "");

    match result {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => assert(
            *panic_data.at(0) == 'Message cannot be empty', *panic_data.at(0),
        ),
    }
}

#[test]
fn test_delete_all_messages() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    // Store test messages
    dispatcher.store_message(recipient, "Temp 1");
    dispatcher.store_message(recipient, "Temp 2");

    // Delete all messages
    dispatcher.delete_all_messages(recipient);

    // Verify deletion
    let remaining = dispatcher.get_all_messages(recipient);
    assert(remaining.len() == 0, 'All messages should be deleted');
}

#[test]
fn test_delete_single_message() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    // Store test messages
    dispatcher.store_message(recipient, "First");
    dispatcher.store_message(recipient, "Second");
    dispatcher.store_message(recipient, "Third");

    // Delete middle message (index 1)
    dispatcher.delete_message(recipient, 1);

    // Verify remaining messages
    let remaining = dispatcher.get_all_messages(recipient);
    assert(remaining.len() == 2, 'Should have 2 messages left');
}

#[test]
fn test_delete_last_message() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    dispatcher.store_message(recipient, "Lone message");
    dispatcher.delete_message(recipient, 0);
    
    assert(dispatcher.get_all_messages(recipient).len() == 0, 'Last message should be deleted');
}

#[test]
#[should_panic(expected: 'Invalid message index')]
fn test_delete_invalid_index_panics() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    dispatcher.store_message(recipient, "Only message");
    dispatcher.delete_message(recipient, 1);
}


// additional test suite
#[test]
fn test_multiple_recipients_isolation() {
    let (dispatcher, _) = deploy_contract();
    
    let alice: ContractAddress = 'alice'.try_into().unwrap();
    let bob: ContractAddress = 'bob'.try_into().unwrap();
    let charlie: ContractAddress = 'charlie'.try_into().unwrap();
    
    // Store different messages for each recipient
    dispatcher.store_message(alice, "Alice's first message");
    dispatcher.store_message(alice, "Alice's second message");
    
    dispatcher.store_message(bob, "Bob's only message");
    
    dispatcher.store_message(charlie, "Charlie's first message");
    dispatcher.store_message(charlie, "Charlie's second message");
    dispatcher.store_message(charlie, "Charlie's third message");
    
    // Verify each recipient has correct number of messages
    let alice_messages = dispatcher.get_all_messages(alice);
    let bob_messages = dispatcher.get_all_messages(bob);
    let charlie_messages = dispatcher.get_all_messages(charlie);
    
    assert(alice_messages.len() == 2, 'Alice should have 2 messages');
    assert(bob_messages.len() == 1, 'Bob should have 1 message');
    assert(charlie_messages.len() == 3, 'Charlie should have 3 messages');
    
    // Verify message content isolation
    assert(alice_messages.at(0) == @"Alice's first message", 'Alice msg 1 wrong');
    assert(bob_messages.at(0) == @"Bob's only message", 'Bob msg wrong');
    assert(charlie_messages.at(2) == @"Charlie's third message", 'Charlie msg 3 wrong');
}

#[test]
fn test_large_message_storage() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    // Test with a long message
    let long_message: ByteArray = "This is a very long message that contains a lot of text to test the storage capacity and handling of large ByteArray messages in the contract storage system.";
    
    dispatcher.store_message(recipient, long_message.clone());
    
    let retrieved = dispatcher.get_message(recipient, 0);
    assert(retrieved == long_message, 'Long message stored ok');
}

#[test]
fn test_unicode_and_special_characters() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    // Test with special characters and unicode
    let special_msg: ByteArray = "Hello! @#$%^&*()_+{}|:<>?[];',./";
    let number_msg: ByteArray = "Numbers: 1234567890";
    
    dispatcher.store_message(recipient, special_msg.clone());
    dispatcher.store_message(recipient, number_msg.clone());
    
    let all_messages = dispatcher.get_all_messages(recipient);
    assert(all_messages.len() == 2, 'Should have 2 special messages');
    
    assert(all_messages.at(0) == @special_msg, 'Special chars message wrong');
    assert(all_messages.at(1) == @number_msg, 'Number message wrong');
}

#[test]
fn test_message_ordering() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    // Store messages in specific order
    dispatcher.store_message(recipient, "First message");
    dispatcher.store_message(recipient, "Second message");
    dispatcher.store_message(recipient, "Third message");
    dispatcher.store_message(recipient, "Fourth message");
    dispatcher.store_message(recipient, "Fifth message");
    
    let all_messages = dispatcher.get_all_messages(recipient);
    assert(all_messages.len() == 5, 'Should have 5 messages');
    
    // Verify order is maintained
    assert(all_messages.at(0) == @"First message", 'Order wrong at index 0');
    assert(all_messages.at(1) == @"Second message", 'Order wrong at index 1');
    assert(all_messages.at(2) == @"Third message", 'Order wrong at index 2');
    assert(all_messages.at(3) == @"Fourth message", 'Order wrong at index 3');
    assert(all_messages.at(4) == @"Fifth message", 'Order wrong at index 4');
}

#[test]
fn test_delete_first_message() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    // Store multiple messages
    dispatcher.store_message(recipient, "Message 1");
    dispatcher.store_message(recipient, "Message 2");
    dispatcher.store_message(recipient, "Message 3");
    
    // Delete the first message
    dispatcher.delete_message(recipient, 0);
    
    let remaining = dispatcher.get_all_messages(recipient);
    assert(remaining.len() == 2, 'Should have 2 after deletion');
    
    // Verify remaining messages are correct
    assert(remaining.at(0) == @"Message 2", 'First remaining message wrong');
    assert(remaining.at(1) == @"Message 3", 'Second remaining message wrong');
}

#[test]
fn test_delete_middle_message() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    // Store multiple messages
    dispatcher.store_message(recipient, "Keep 1");
    dispatcher.store_message(recipient, "Delete this");
    dispatcher.store_message(recipient, "Keep 2");
    dispatcher.store_message(recipient, "Keep 3");
    
    // Delete the middle message (index 1)
    dispatcher.delete_message(recipient, 1);
    
    let remaining = dispatcher.get_all_messages(recipient);
    assert(remaining.len() == 3, 'Should have 3 after deletion');
    
    // Verify correct messages remain
    assert(remaining.at(0) == @"Keep 1", 'First remaining wrong');
    assert(remaining.at(1) == @"Keep 2", 'Second remaining wrong');
    assert(remaining.at(2) == @"Keep 3", 'Third remaining wrong');
}

#[test]
fn test_empty_recipient_messages() {
    let (dispatcher, _) = deploy_contract();
    let empty_recipient: ContractAddress = 'empty'.try_into().unwrap();
    
    // Get messages for recipient with no messages
    let messages = dispatcher.get_all_messages(empty_recipient);
    assert(messages.len() == 0, 'Empty recipient has no messages');
}

#[test]
#[should_panic(expected: 'Index out of bounds')]
fn test_get_message_out_of_bounds() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    // Store one message
    dispatcher.store_message(recipient, "Only message");
    
    // Try to access index 1 (should panic)
    dispatcher.get_message(recipient, 1);
}

#[test]
#[should_panic(expected: 'Index out of bounds')]
fn test_get_message_from_empty_recipient() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'empty'.try_into().unwrap();
    
    // Try to get message from recipient with no messages
    dispatcher.get_message(recipient, 0);
}

#[test]
fn test_sequential_delete_operations() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    // Store multiple messages
    dispatcher.store_message(recipient, "Msg 1");
    dispatcher.store_message(recipient, "Msg 2");
    dispatcher.store_message(recipient, "Msg 3");
    dispatcher.store_message(recipient, "Msg 4");
    
    // Delete messages one by one from the beginning
    dispatcher.delete_message(recipient, 0); // Delete "Msg 1"
    let remaining1 = dispatcher.get_all_messages(recipient);
    assert(remaining1.len() == 3, 'Should have 3 after 1st delete');
    
    dispatcher.delete_message(recipient, 0); // Delete "Msg 2" (now at index 0)
    let remaining2 = dispatcher.get_all_messages(recipient);
    assert(remaining2.len() == 2, 'Should have 2 after 2nd delete');
    
    dispatcher.delete_message(recipient, 0); // Delete "Msg 3" (now at index 0)
    let remaining3 = dispatcher.get_all_messages(recipient);
    assert(remaining3.len() == 1, 'Should have 1 after 3rd delete');
    
    // Verify last remaining message
    assert(remaining3.at(0) == @"Msg 4", 'Last message should be Msg 4');
}

#[test]
fn test_store_after_delete_all() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    // Store initial messages
    dispatcher.store_message(recipient, "Initial 1");
    dispatcher.store_message(recipient, "Initial 2");
    
    // Delete all messages
    dispatcher.delete_all_messages(recipient);
    assert(dispatcher.get_all_messages(recipient).len() == 0, 'Should be empty after delete');
    
    // Store new messages after deletion
    dispatcher.store_message(recipient, "New 1");
    dispatcher.store_message(recipient, "New 2");
    
    let new_messages = dispatcher.get_all_messages(recipient);
    assert(new_messages.len() == 2, 'Should have 2 new messages');
    assert(new_messages.at(0) == @"New 1", 'First new message wrong');
    assert(new_messages.at(1) == @"New 2", 'Second new message wrong');
}

#[test]
fn test_single_character_messages() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    // Test single character messages
    dispatcher.store_message(recipient, "a");
    dispatcher.store_message(recipient, "1");
    dispatcher.store_message(recipient, "!");
    
    let messages = dispatcher.get_all_messages(recipient);
    assert(messages.len() == 3, 'Should have 3 single-char msgs');
    
    assert(messages.at(0) == @"a", 'Single char a wrong');
    assert(messages.at(1) == @"1", 'Single char 1 wrong');
    assert(messages.at(2) == @"!", 'Single char ! wrong');
}

#[test]
fn test_bulk_message_operations() {
    let (dispatcher, _) = deploy_contract();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    
    // Store many messages
    dispatcher.store_message(recipient, "Bulk message 1");
    dispatcher.store_message(recipient, "Bulk message 2");
    dispatcher.store_message(recipient, "Bulk message 3");
    dispatcher.store_message(recipient, "Bulk message 4");
    dispatcher.store_message(recipient, "Bulk message 5");
    dispatcher.store_message(recipient, "Bulk message 6");
    dispatcher.store_message(recipient, "Bulk message 7");
    dispatcher.store_message(recipient, "Bulk message 8");
    dispatcher.store_message(recipient, "Bulk message 9");
    dispatcher.store_message(recipient, "Bulk message 10");
    
    let all_messages = dispatcher.get_all_messages(recipient);
    assert(all_messages.len() == 10, 'Should have 10 bulk messages');
    
    // Verify specific messages
    assert(all_messages.at(0) == @"Bulk message 1", 'Bulk message 1 wrong');
    assert(all_messages.at(4) == @"Bulk message 5", 'Bulk message 5 wrong');
    assert(all_messages.at(9) == @"Bulk message 10", 'Bulk message 10 wrong');
    
    // Test individual retrieval
    let msg_5 = dispatcher.get_message(recipient, 4);
    assert(msg_5 == "Bulk message 5", 'Individual retrieval wrong');
}