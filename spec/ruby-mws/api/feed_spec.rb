require 'spec_helper'

describe MWS::API::Feed do

  before :all do
    EphemeralResponse.activate
  end

  context "requests" do
    let(:mws) {@mws = MWS.new(auth_params)}
    let(:first_order_id) {'105-8268075-6520231'}
    let(:second_order_id) {'105-8268075-6520232'}
    let(:orders_hash) {
      {
        :orders => [ {
                       :amazon_order_id => first_order_id,
                       :shipping_method => '2nd Day',
                       :items => [
                                  {
                                    :amazon_order_item_code => '27030690916666',
                                    :quantity => 1
                                  },
                                  {
                                    :amazon_order_item_code => '62918663121794',
                                    :quantity => 1
                                  }
                                 ]
                     },{
                       :amazon_order_id => second_order_id,
                       :shipping_method => '2nd Day',
                       :items => [
                                  {
                                    :amazon_order_item_code => '27030690916662',
                                    :quantity => 2,
                                    :merchant_order_item_id => 11
                                  },
                                  {
                                    :amazon_order_item_code => '62918663121792',
                                    :quantity => 2,
                                    :merchant_order_item_id => 12
                                  }
                                 ]
                     } ]
      }
    }

    describe "submit_feed" do
      it "should be able to ack an order" do
        response = mws.feeds.submit_feed(MWS::API::Feed::ORDER_ACK, {
                                            :amazon_order_id => '105-1063273-7151427',
                                            :merchant_order_id => 10
                                          })
        response.feed_submission_info.should_not be_nil

        info = response.feed_submission_info
        info.feed_processing_status.should == "_SUBMITTED_"
        info.feed_type.should == MWS::API::Feed::ORDER_ACK
      end

      it "should be able to ack a shipment" do
        response = mws.feeds.submit_feed(MWS::API::Feed::SHIP_ACK, orders_hash)
        response.feed_submission_info.should_not be_nil

        info = response.feed_submission_info
        info.feed_processing_status.should == "_SUBMITTED_"
        info.feed_type.should == MWS::API::Feed::SHIP_ACK
      end

      it "should create the correct body for shipment" do
        MWS::API::Feed.should_receive(:post) do |uri, hash|
          hash.should include(:body)
          body = hash[:body]
          
          body_doc = Nokogiri.parse(body)
          ids = body_doc.css('AmazonEnvelope Message OrderFulfillment AmazonOrderID')

          ids.should_not be_empty
          ids[0].text.should == first_order_id
          ids[1].text.should == second_order_id
          
          body_doc.css('AmazonEnvelope Message Item').should_not be_empty
        end
        response = mws.feeds.submit_feed(MWS::API::Feed::SHIP_ACK, orders_hash)
      end
    end
    
    describe "callback block" do
      let(:response_callback) {double("callback", :call => nil)}
      let(:mws) {MWS.new(auth_params.merge(:response_callback => response_callback))}

      it "should be called on list order items" do
        expect(response_callback).to receive(:call)
        response = mws.feeds.submit_feed(MWS::API::Feed::ORDER_ACK, {
                                           :amazon_order_id => '105-1063273-7151427'
                                         })

      end
    end
  end
end
