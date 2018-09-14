require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the AppsHelper. For example:
#
# describe AppsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
describe AppsHelper do

  describe ".head_seo_pagination" do
    it {
      helper.head_seo_pagination(1).should == ''
    }

    it {
      helper.head_seo_pagination(2).should == tag('link', { :rel => 'next', :href => '/?page=2' })
    }

    it {
      helper.head_seo_pagination(10).should == tag('link', { :rel => 'next', :href => '/?page=2' })
    }

    it {
      helper.stub(:params).and_return({ page: 2 })
      helper.head_seo_pagination(1).should == ''
    }

    it {
      helper.stub(:params).and_return({ page: 2 })
      helper.head_seo_pagination(2).should == tag('link', { :rel => 'prev', :href => '/' })
    }

    it {
      helper.stub(:params).and_return({ page: 2 })
      helper.head_seo_pagination(10).should == tag('link', { :rel => 'prev', :href => '/' }) + tag('link', { :rel => 'next', :href => '/?page=3' })
    }

    it {
      helper.stub(:params).and_return({ page: 3 })
      helper.head_seo_pagination(10).should == tag('link', { :rel => 'prev', :href => '/?page=2' }) + tag('link', { :rel => 'next', :href => '/?page=4' })
    }

    it {
      helper.stub(:params).and_return({ order: 'rating' })
      helper.head_seo_pagination(1).should == ''
    }

    it {
      helper.stub(:params).and_return({ order: 'rating' })
      helper.head_seo_pagination(2).should == tag('link', { :rel => 'next', :href => '/?order=rating&page=2' })
    }

    it {
      helper.stub(:params).and_return({ order: 'rating' })
      helper.head_seo_pagination(10).should == tag('link', { :rel => 'next', :href => '/?order=rating&page=2' })
    }

    it {
      helper.stub(:params).and_return({ order: 'rating', page: 2 })
      helper.head_seo_pagination(1).should == ''
    }

    it {
      helper.stub(:params).and_return({ order: 'rating', page: 2 })
      helper.head_seo_pagination(2).should == tag('link', { :rel => 'prev', :href => '/?order=rating' })
    }

    it {
      helper.stub(:params).and_return({ order: 'rating', page: 2 })
      helper.head_seo_pagination(10).should == tag('link', { :rel => 'prev', :href => '/?order=rating' }) + tag('link', { :rel => 'next', :href => '/?order=rating&page=3' })
    }

    it {
      helper.stub(:params).and_return({ order: 'rating', page: 3 })
      helper.head_seo_pagination(10).should == tag('link', { :rel => 'prev', :href => '/?order=rating&page=2' }) + tag('link', { :rel => 'next', :href => '/?order=rating&page=4' })
    }
  end

end
