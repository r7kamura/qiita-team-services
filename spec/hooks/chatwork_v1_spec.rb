describe Qiita::Team::Services::Hooks::ChatworkV1 do
  include Qiita::Team::Services::Helpers::EventHelper
  include Qiita::Team::Services::Helpers::HttpClientStubHelper
  include Qiita::Team::Services::Helpers::HookHelper

  EXPECTED_AVAILABLE_EVENT_NAMES = [
    :item_became_coediting,
    :item_comment_created,
    :item_created,
    :item_updated,
    :project_activated,
    :project_archived,
    :project_comment_created,
    :project_created,
    :project_updated,
    :team_member_added,
  ].freeze

  shared_context "Delivery success" do
    before do
      stubs = get_http_client_stub(hook)
      stubs.post("/v1/rooms/#{room_id}/messages") do |_env|
        [200, { "Content-Type" => "application/json" }, { message_id: 1 }]
      end
    end
  end

  shared_context "Delivery fail" do
    before do
      stubs = get_http_client_stub(hook)
      stubs.post("/v1/rooms/#{room_id}/messages") do |_env|
        [400, {}, ""]
      end
    end
  end

  subject(:hook) do
    described_class.new(properties)
  end

  let(:properties) do
    { "room_id" => room_id, "token" => token }
  end

  let(:room_id) do
    1
  end

  let(:token) do
    "abc"
  end

  it_behaves_like "hook"

  describe ".service_name" do
    subject do
      described_class.service_name
    end

    it { should eq "ChatWork" }
  end

  describe ".available_event_names" do
    subject do
      described_class.available_event_names
    end

    it { should match_array EXPECTED_AVAILABLE_EVENT_NAMES }
  end

  describe "#ping" do
    subject do
      hook.ping
    end

    it "sends a text message" do
      expect(hook).to receive(:send_message).with(a_kind_of(String))
      subject
    end

    context "when message is delivered successful" do
      include_context "Delivery success"

      it { expect { subject }.not_to raise_error }
    end

    context "when message is not delivered" do
      include_context "Delivery fail"

      it { expect { subject }.not_to raise_error }
    end
  end

  EXPECTED_AVAILABLE_EVENT_NAMES.each do |event_name|
    describe "##{event_name}" do
      subject do
        hook.public_send(event_name, public_send("#{event_name}_event"))
      end

      it "sends a text message" do
        expect(hook).to receive(:send_message).with(a_kind_of(String))
        subject
      end

      context "when message is delivered successfully" do
        include_context "Delivery success"

        it { expect { subject }.not_to raise_error }
      end

      context "when message is not delivered successfully" do
        include_context "Delivery fail"

        it { expect { subject }.to raise_error(Qiita::Team::Services::DeliveryError) }
      end
    end
  end
end
