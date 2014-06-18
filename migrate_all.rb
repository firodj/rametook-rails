#!./script/runner

AddressbookContact.find(:all).each { |contact|
contact.migrate
}


