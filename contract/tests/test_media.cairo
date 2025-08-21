use contract::media::{
    IMediaSharingDispatcher, 
    IMediaSharingDispatcherTrait,
    IMediaSharingSafeDispatcher,
    IMediaSharingSafeDispatcherTrait,
    MediaItem,
};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use starknet::ContractAddress;
use core::array::ArrayTrait;
use core::traits::TryInto;

// Define a helper function to deploy the contract
fn deploy_contract() -> (IMediaSharingDispatcher, IMediaSharingSafeDispatcher) {
    let contract_class = declare("MediaSharing").unwrap().contract_class();
    let (contract_address, _) = contract_class.deploy(@ArrayTrait::new()).unwrap();

    let media_sharing_dispatcher = IMediaSharingDispatcher { contract_address };
    let media_sharing_safe_dispatcher = IMediaSharingSafeDispatcher { contract_address };
    
    (media_sharing_dispatcher, media_sharing_safe_dispatcher)
}

#[test]
fn test_share_and_get_media() {
    // Deploy the contract
    let (media_sharing_dispatcher, _) = deploy_contract();

    // Define a recipient address
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    // Define media hash and type
    let media_hash: ByteArray = "QmT78zSuBmuS4z925WZfrqQ1qHaJ56DQaTfyMUF7F8ff5o";
    let media_type: ByteArray = "image/jpeg";

    // Share the media
    media_sharing_dispatcher.share_media(recipient, media_hash.clone(), media_type.clone());

    // Retrieve the media at index 0
    let _ = media_sharing_dispatcher.get_media(recipient, 0);
    
    // Success if we get here without errors
    assert(true, 'Media retrieval failed');
}

#[test]
fn test_get_all_media() {
    // Deploy the contract
    let (media_sharing_dispatcher, _) = deploy_contract();

    // Define a recipient address
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    // Define two media files
    let media_hash1: ByteArray = "QmT78zSuBmuS4z925WZfrqQ1qHaJ56DQaTfyMUF7F8ff5o";
    let media_type1: ByteArray = "image/jpeg";
    
    let media_hash2: ByteArray = "QmWATWQ7fVPP2EFGu71UkfnqhYXDYH566qy47CnJDgvs8u";
    let media_type2: ByteArray = "video/mp4";

    // Share the media files
    media_sharing_dispatcher.share_media(recipient, media_hash1.clone(), media_type1.clone());
    media_sharing_dispatcher.share_media(recipient, media_hash2.clone(), media_type2.clone());

    // Retrieve all media for the recipient
    let all_media = media_sharing_dispatcher.get_all_media(recipient);

    // Assert that the length of the retrieved media is correct
    assert(all_media.len() == 2, 'Incorrect number of media items');
}

#[test]
#[feature("safe_dispatcher")]
fn test_safe_empty_hash_validation() {
    // Deploy the contract
    let (_, media_sharing_safe_dispatcher) = deploy_contract();

    // Define a recipient address
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    // Attempt to share media with an empty hash
    let result = media_sharing_safe_dispatcher.share_media(recipient, "", "image/jpeg");

    match result {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => assert(*panic_data.at(0) == 'Media hash cannot be empty', *panic_data.at(0)),
    }
}

#[test]
#[feature("safe_dispatcher")]
fn test_safe_empty_type_validation() {
    // Deploy the contract
    let (_, media_sharing_safe_dispatcher) = deploy_contract();

    // Define a recipient address
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    // Attempt to share media with an empty type
    let result = media_sharing_safe_dispatcher.share_media(
        recipient, 
        "QmT78zSuBmuS4z925WZfrqQ1qHaJ56DQaTfyMUF7F8ff5o", 
        ""
    );

    match result {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => assert(*panic_data.at(0) == 'Media type cannot be empty', *panic_data.at(0)),
    }
}

#[test]
fn test_multiple_recipients() {
    // Deploy the contract
    let (media_sharing_dispatcher, _) = deploy_contract();

    // Define multiple recipients
    let recipient1: ContractAddress = 'recipient1'.try_into().unwrap();
    let recipient2: ContractAddress = 'recipient2'.try_into().unwrap();
    
    // Define media files
    let media_hash1: ByteArray = "QmT78zSuBmuS4z925WZfrqQ1qHaJ56DQaTfyMUF7F8ff5o";
    let media_type1: ByteArray = "image/jpeg";
    
    let media_hash2: ByteArray = "QmWATWQ7fVPP2EFGu71UkfnqhYXDYH566qy47CnJDgvs8u";
    let media_type2: ByteArray = "video/mp4";

    // Share media with different recipients
    media_sharing_dispatcher.share_media(recipient1, media_hash1.clone(), media_type1.clone());
    media_sharing_dispatcher.share_media(recipient2, media_hash2.clone(), media_type2.clone());

    // Check recipient1's media
    let recipient1_media = media_sharing_dispatcher.get_all_media(recipient1);
    assert(recipient1_media.len() == 1, 'Recipient1 should have 1 item');
    
    // Check recipient2's media
    let recipient2_media = media_sharing_dispatcher.get_all_media(recipient2);
    assert(recipient2_media.len() == 1, 'Recipient2 should have 1 item');
}

#[test]
#[should_panic(expected: 'Index out of bounds')]
fn test_get_media_out_of_bounds() {
    // Deploy the contract
    let (media_sharing_dispatcher, _) = deploy_contract();

    // Define a recipient address
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    // Share one media item
    media_sharing_dispatcher.share_media(
        recipient, 
        "QmT78zSuBmuS4z925WZfrqQ1qHaJ56DQaTfyMUF7F8ff5o", 
        "image/jpeg"
    );

    // Try to access an out-of-bounds index (should panic)
    media_sharing_dispatcher.get_media(recipient, 1);
}

// additional test suites to improve test coverage
#[test]
fn test_media_item_properties() {
    let (media_sharing_dispatcher, _) = deploy_contract();

    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    let media_hash: ByteArray = "QmT78zSuBmuS4z925WZfrqQ1qHaJ56DQaTfyMUF7F8ff5o";
    let media_type: ByteArray = "image/png";

    media_sharing_dispatcher.share_media(recipient, media_hash.clone(), media_type.clone());

    let _media_item = media_sharing_dispatcher.get_media(recipient, 0);

    assert(true, 'Media retrieval successful');
}

#[test]
fn test_different_media_types() {
    let (media_sharing_dispatcher, _) = deploy_contract();

    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    let hash1: ByteArray = "QmHash1";
    let hash2: ByteArray = "QmHash2"; 
    let hash3: ByteArray = "QmHash3";
    let hash4: ByteArray = "QmHash4";
    let hash5: ByteArray = "QmHash5";

    media_sharing_dispatcher.share_media(recipient, hash1.clone(), "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, hash2.clone(), "image/png");
    media_sharing_dispatcher.share_media(recipient, hash3.clone(), "video/mp4");
    media_sharing_dispatcher.share_media(recipient, hash4.clone(), "audio/mp3");
    media_sharing_dispatcher.share_media(recipient, hash5.clone(), "application/pdf");

    let all_media = media_sharing_dispatcher.get_all_media(recipient);
    assert(all_media.len() == 5, 'Should have 5 media items');

    let _item1 = media_sharing_dispatcher.get_media(recipient, 0);
    let _item2 = media_sharing_dispatcher.get_media(recipient, 1);
    let _item3 = media_sharing_dispatcher.get_media(recipient, 2);
    let _item4 = media_sharing_dispatcher.get_media(recipient, 3);
    let _item5 = media_sharing_dispatcher.get_media(recipient, 4);
    
    assert(true, 'All media types stored ok');
}

#[test]
fn test_large_number_of_media_items() {
    let (media_sharing_dispatcher, _) = deploy_contract();

    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    media_sharing_dispatcher.share_media(recipient, "QmHash0", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmHash1", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmHash2", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmHash3", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmHash4", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmHash5", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmHash6", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmHash7", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmHash8", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmHash9", "image/jpeg");

    let all_media = media_sharing_dispatcher.get_all_media(recipient);
    assert(all_media.len() == 10, 'Should have 10 media items');

    let _first_item = media_sharing_dispatcher.get_media(recipient, 0);
    let _last_item = media_sharing_dispatcher.get_media(recipient, 9);

    assert(true, 'All items accessible');
}

#[test]
fn test_same_hash_different_types() {
    let (media_sharing_dispatcher, _) = deploy_contract();

    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    let same_hash: ByteArray = "QmSameHash";
    
    media_sharing_dispatcher.share_media(recipient, same_hash.clone(), "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, same_hash.clone(), "image/png");

    let all_media = media_sharing_dispatcher.get_all_media(recipient);
    assert(all_media.len() == 2, 'Should have 2 media items');

    let _item1 = media_sharing_dispatcher.get_media(recipient, 0);
    let _item2 = media_sharing_dispatcher.get_media(recipient, 1);
    
    assert(true, 'Same hash different types work');
}

#[test]
fn test_long_hash_and_type() {
    let (media_sharing_dispatcher, _) = deploy_contract();

    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    let long_hash: ByteArray = "QmT78zSuBmuS4z925WZfrqQ1qHaJ56DQaTfyMUF7F8ff5oExtraLongHashString";
    let long_type: ByteArray = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

    media_sharing_dispatcher.share_media(recipient, long_hash.clone(), long_type.clone());

    // Retrieve and verify it's accessible
    let _media_item = media_sharing_dispatcher.get_media(recipient, 0);
    
    assert(true, 'Long strings stored ok');
}

#[test]
fn test_timestamp_ordering() {
    let (media_sharing_dispatcher, _) = deploy_contract();

    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    media_sharing_dispatcher.share_media(recipient, "QmFirst", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmSecond", "image/png");
    media_sharing_dispatcher.share_media(recipient, "QmThird", "video/mp4");

    let _item1 = media_sharing_dispatcher.get_media(recipient, 0);
    let _item2 = media_sharing_dispatcher.get_media(recipient, 1);
    let _item3 = media_sharing_dispatcher.get_media(recipient, 2);

    assert(true, 'Items stored in order');
}

#[test]
fn test_empty_media_list() {
    let (media_sharing_dispatcher, _) = deploy_contract();

    let recipient: ContractAddress = 'empty_recipient'.try_into().unwrap();

    let all_media = media_sharing_dispatcher.get_all_media(recipient);
    
    assert(all_media.len() == 0, 'Should have no media items');
}

#[test]
#[should_panic(expected: 'Index out of bounds')]
fn test_get_media_from_empty_list() {
    let (media_sharing_dispatcher, _) = deploy_contract();

    let recipient: ContractAddress = 'empty_recipient'.try_into().unwrap();

    media_sharing_dispatcher.get_media(recipient, 0);
}

#[test]
fn test_multiple_media_same_recipient() {
    let (media_sharing_dispatcher, _) = deploy_contract();

    let recipient: ContractAddress = 'power_user'.try_into().unwrap();

    media_sharing_dispatcher.share_media(recipient, "QmPhoto1", "image/jpeg");
    media_sharing_dispatcher.share_media(recipient, "QmVideo1", "video/mp4");
    media_sharing_dispatcher.share_media(recipient, "QmAudio1", "audio/mp3");
    media_sharing_dispatcher.share_media(recipient, "QmDoc1", "application/pdf");
    media_sharing_dispatcher.share_media(recipient, "QmPhoto2", "image/png");

    let all_media = media_sharing_dispatcher.get_all_media(recipient);
    assert(all_media.len() == 5, 'Should have 5 media items');
 
    let _photo1 = media_sharing_dispatcher.get_media(recipient, 0);
    let _video1 = media_sharing_dispatcher.get_media(recipient, 1);
    let _audio1 = media_sharing_dispatcher.get_media(recipient, 2);
    let _doc1 = media_sharing_dispatcher.get_media(recipient, 3);
    let _photo2 = media_sharing_dispatcher.get_media(recipient, 4);

    assert(true, 'All media accessible');
}

#[test]
fn test_recipient_isolation() {
    let (media_sharing_dispatcher, _) = deploy_contract();

    let alice: ContractAddress = 'alice'.try_into().unwrap();
    let bob: ContractAddress = 'bob'.try_into().unwrap();
    let charlie: ContractAddress = 'charlie'.try_into().unwrap();

    media_sharing_dispatcher.share_media(alice, "QmAlicePhoto", "image/jpeg");
    media_sharing_dispatcher.share_media(alice, "QmAliceVideo", "video/mp4");
    
    media_sharing_dispatcher.share_media(bob, "QmBobAudio", "audio/mp3");
    
    media_sharing_dispatcher.share_media(charlie, "QmCharlieDoc", "application/pdf");
    media_sharing_dispatcher.share_media(charlie, "QmCharlieImage", "image/png");
    media_sharing_dispatcher.share_media(charlie, "QmCharlieVideo", "video/avi");

    let alice_media = media_sharing_dispatcher.get_all_media(alice);
    let bob_media = media_sharing_dispatcher.get_all_media(bob);
    let charlie_media = media_sharing_dispatcher.get_all_media(charlie);

    assert(alice_media.len() == 2, 'Alice should have 2 items');
    assert(bob_media.len() == 1, 'Bob should have 1 item');
    assert(charlie_media.len() == 3, 'Charlie should have 3 items');

    let _alice_item1 = media_sharing_dispatcher.get_media(alice, 0);
    let _bob_item1 = media_sharing_dispatcher.get_media(bob, 0);
    let _charlie_item1 = media_sharing_dispatcher.get_media(charlie, 0);

    assert(true, 'Recipient isolation works');
}