require 'spec_helper'

describe 'sdc-listsnapshots' do
  let(:ssh_fingerprint) { '9f:65:42:51:e7:1d:f7:ab:45:12:42:aa:4c:37:97:b8' }
  let(:sdc_output) { Oj.dump(snapshot_list, indent: 2) }
  let(:zonename) { 'machine_uuid' }

  let(:valid_environment) {
    {
      'PATH' => ENV['PATH'],
      'HOME' => '/home/user',
      'SSH_AUTH_SOCK' => '/dev/null',
      'SDC_URL' => 'https://joyent/sdc/url',
      'SDC_ACCOUNT' => 'sdc_account_name',
      'SDC_KEY_ID' => ssh_fingerprint
    }
  }

  let(:snapshot_list) { [{name: "blah", state: 'created', created: '2013-12-10T08:11:03.000Z'}] }

  before do
    double_cmd('sdc-listmachinesnapshots', puts: sdc_output)
    double_cmd('zonename', puts: zonename)
  end

  context 'without SDC_KEY_ID' do
    let(:ssh_fingerprint) { 'derpderpderp' }
    let(:environment) { valid_environment.reject { |k, v| k == 'SDC_KEY_ID' }.merge('HOME' => '/path/to/home') }

    before { double_cmd('ssh-keygen', puts: "4096 #{ssh_fingerprint} /path/to/home/.ssh/sdc-snapshot.pub (RSA)") }

    it 'generates fingerprint of sdc-snapshot.pub from HOME' do
      expect {
        system(environment, 'bin/sdc-listsnapshots', unsetenv_others: true)
      }.to shellout("ssh-keygen -l -f /path/to/home/.ssh/sdc-snapshot.pub")
    end

    it 'uses the generated ssh fingerprint in sdc-listmachinesnapshots' do
      binding.pry
      expect {
        system(environment, 'bin/sdc-listsnapshots', unsetenv_others: true)
      }.to shellout("sdc-listmachinesnapshots --debug --keyId #{ssh_fingerprint} #{zonename}")
    end
  end

  context 'with valid environment' do
    it 'runs sdc-listmachinesnapshots with zonename and keyId' do
      expect {
        system(valid_environment, 'bin/sdc-listsnapshots', unsetenv_others: true)
      }.to shellout("sdc-listmachinesnapshots --debug --keyId #{ssh_fingerprint} #{zonename}")
    end

    it 'outputs names of snapshots' do
      io = IO.popen(valid_environment, ['bin/sdc-listsnapshots', :err=>[:child, :out]], unsetenv_others: true)
      Process.wait
      expect(io.read).to eq('blah')
    end
  end
end
