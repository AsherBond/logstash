# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'spec_helper'
require 'pluginmanager/main'

describe LogStash::PluginManager::Update do
  let(:cmd)     { LogStash::PluginManager::Update.new("update") }
  let(:sources) { cmd.gemfile.gemset.sources }
  let(:expect_preflight_error) { false } # hack to bypass before-hook expectations

  before(:each) do
    unless expect_preflight_error
      expect(cmd).to receive(:find_latest_gem_specs).and_return({})
      allow(cmd).to receive(:warn_local_gems).and_return(nil)
      expect(cmd).to receive(:display_updated_plugins).and_return(nil)
    end
  end

  it "pass all gem sources to the bundle update command" do
    sources = cmd.gemfile.gemset.sources
    expect_any_instance_of(LogStash::Bundler).to receive(:invoke!).with(
        :update => [],
        :rubygems_source => sources,
        :conservative => true,
        :local => false,
        :level => "minor" # default
    )
    cmd.execute
  end

  context "when skipping validation" do
    let(:cmd)    { LogStash::PluginManager::Update.new("update") }
    let(:plugin) { OpenStruct.new(:name => "dummy", :options => {}) }

    before(:each) do
      expect(cmd.gemfile).to receive(:find).with(plugin).and_return(plugin)
      expect(cmd.gemfile).to receive(:save).and_return(nil)
      expect(cmd).to receive(:plugins_to_update).and_return([plugin])
      expect_any_instance_of(LogStash::Bundler).to receive(:invoke!).with(
        hash_including(:update => [plugin], :rubygems_source => sources, :level => "minor")
      ).and_return(nil)
    end

    it "skips version verification when ask for it" do
      expect(cmd).to_not receive(:validates_version)
      cmd.run(["--no-verify"])
    end
  end

  context "with explicit `--level` flag" do
    LogStash::PluginManager::Update::SUPPORTED_LEVELS.each do |level|
      context "with --level=#{level} (valid)" do
        let(:requested_level) { level }

        let(:cmd)    { LogStash::PluginManager::Update.new("update") }
        let(:plugin) { OpenStruct.new(:name => "dummy", :options => {}) }

        before(:each) do
          cmd.verify = false
        end

        it "propagates the level flag as an option to Bundler#invoke!" do
          expect(cmd.gemfile).to receive(:find).with(plugin).and_return(plugin)
          expect(cmd.gemfile).to receive(:save).and_return(nil)
          expect(cmd).to receive(:plugins_to_update).and_return([plugin])
          expect_any_instance_of(LogStash::Bundler).to receive(:invoke!).with(
            hash_including(:update => [plugin], :rubygems_source => sources, :level => requested_level)
          ).and_return(nil)

          cmd.run(["--level=#{requested_level}"])
        end
      end
    end

    context "with --level=eVeRyThInG (invalid)" do
      let(:requested_level) { "eVeRyThInG" }
      let(:expect_preflight_error) { true }

      let(:cmd)    { LogStash::PluginManager::Update.new("update") }
      let(:plugin) { OpenStruct.new(:name => "dummy", :options => {}) }

      it "errors helpfully" do
        expect { cmd.run(["--level=#{requested_level}"]) }
          .to raise_error.with_message(including("unsupported level `#{requested_level}`"))
      end
    end
  end
end
