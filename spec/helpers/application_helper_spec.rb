require 'spec_helper'

describe ApplicationHelper do
  it 'should display language name by abbr' do
    LANG_LIST.keys.should be_all{ |k| LANG_LIST[k] == language_name(k) }
    language_name('habrahabr').should == ''
  end

  it 'should display country name by code' do
    country_name.should     be_blank
    country_name('').should be_blank
    country_name('USA').should == 'United States'
  end
end
