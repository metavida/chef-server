# Copyright: Copyright (c) 2012 Opscode, Inc.
# License: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Pedant self-diagnostic tests
#
# This spec results from the fragility of using let() with before(:all) blocks
# The work-around uses shared() for anything referenced in a before(:all) block.
# These tests make sure shared() works, and will have some canary tests to make
# sure what should be in shared() blocks do not slip in.

require 'pedant/rspec/role_util'

describe 'Pedant Self-Diagnostic', :pedantic do
  context 'with shared() and let()' do
    context 'before(:all)' do
      before(:all) { shared_var } # Reference foo in noop

      # If :foo is declared with let(), the examples here will fail.
      shared(:shared_var) { :parent }
      let(:let_var)       { :parent }

      context 'within a child context' do
        let(:shared_var) { :child }
        let(:let_var)    { :child }

        it 'should use the child shared_var' do
          shared_var.should eql :child
        end

        it 'should use the child let_var' do
          let_var.should eql :child
        end
      end

      it 'should use parent shared_var' do
        shared_var.should eql :parent
      end

      it 'should use parent let_var' do
        let_var.should eql :parent
      end
    end
  end

  context 'Integration Users' do
    include Pedant::RSpec::RoleUtil

    shared(:existing_role) { 'web' }

    # If any of these fail, it is because the variable should be shared(), not let()
    def self.should_be_sharing(shared_var_name)
      context "with #{shared_var_name}" do
        before(:all) { send(shared_var_name); add_role(admin_user, new_role(existing_role)) }
        after(:all)  { delete_role(admin_user, existing_role) }

        let(:let_var)       { :parent }

        context 'within a child context' do
          let(:let_var)    { :child }

          it 'should use the child let_var' do
            let_var.should eql :child
          end
        end

        it 'should use parent let_var' do
          let_var.should eql :parent
        end
      end
    end # .should_be_sharing

    should_be_sharing :admin_user
    should_be_sharing :normal_user
    should_be_sharing :outside_user
    should_be_sharing :superuser
  end

  context 'Matchers' do

    describe 'strictly_match' do
      it "works with plain hashes" do
        # Positive case
        {:a => 1, :b => 2}.should strictly_match({:b => 2, :a => 1})

        # Negative case
        {:a => 1, :b => 2}.should_not strictly_match({:b => 2, :a => 3})
      end

      it "works with regex keys" do
        # Positive case
        {:x => "bigfoot"}.should strictly_match({:x => /.*foo.*/})

        # Negative case
        {:x => "bigfoot"}.should_not strictly_match({:x => /.*bar.*/})
      end

      it "works with arrays of scalars, treating them as sets" do
        # Positive case
        {:x => "foo", :y => [3,2,1]}.should strictly_match({:x => "foo", :y => [1,2,3]})

        # Negative case
        {:x => "foo", :y => [3,2,1]}.should_not strictly_match({:x => "foo", :y => [1,2,3,3,3]})
      end

      it "works with hash values" do
        # Positive case
        {
          :x => "foo",
          :y => {:foo => 1, :bar => 2}
        }.should strictly_match({
                                  :x => "foo",
                                  :y => {:foo => 1, :bar => 2}
                                })

        # Negative case
        {
          :x => "foo",
          :y => {:foo => 1, :bar => 2}
        }.should_not strictly_match({
                                      :x => "foo",
                                      :y => {:foo => 42, :bar => 2}
                                    })
      end

      it "should work with nested hashes of specs" do
        # Positive case
        {
          :x => 123,
          :y => {:foo => "bigfoot", :bar => [3,2,1]}
        }.should strictly_match({
                                  :x => 123,
                                  :y => {
                                    :foo => /.*foo.*/,
                                    :bar => [1,2,3]
                                  }
                                })

        # Negative case
        {:x => 123,
          :y => {:foo => "bigfoot", :bar => [3,2,1]}
        }.should_not strictly_match({
                                      :x => 123,
                                      :y => {
                                        :foo => /.*bar.*/,
                                        :bar => [1,2,3]
                                      }})

      end
    end

    describe 'loosely_match' do
      it "works with plain hashes" do
        # Positive case
        {:a => 1, :b => 2}.should loosely_match({:a => 1})

        # Negative case
        {:a => 1, :b => 2}.should_not loosely_match({:a => 3})
      end

      it "works with regex keys" do
        # Positive case
        {:y => 123, :x => "bigfoot"}.should loosely_match({:x => /.*foo.*/})

        # Negative case
        {:y => 123, :x => "bigfoot"}.should_not loosely_match({:x => /.*bar.*/})
      end

      it "works with arrays of scalars, treating them as sets" do
        # Positive case
        {:x => "foo", :y => [3,2,1]}.should loosely_match({:y => [1,2,3]})

        # Negative case
        {:x => "foo", :y => [3,2,1]}.should_not loosely_match({:y => [1,2,3,3,3]})
      end

      it "works with hash values" do
        # Positive case
        {
          :x => "foo",
          :y => {:foo => 1, :bar => 2}
        }.should loosely_match({
                                 :y => {:foo => 1, :bar => 2}
                               })

        # Negative case
        {
          :x => "foo",
          :y => {:foo => 1, :bar => 2}
        }.should_not loosely_match({
                                     :y => {:foo => 42, :bar => 2}
                                   })
      end

      it "should work with nested hashes of specs" do
        # Positive case
        {
          :x => 123,
          :y => {:foo => "bigfoot", :bar => [3,2,1]}
        }.should loosely_match({
                                 :y => {
                                   :foo => /.*foo.*/
                                 }
                               })

        # Negative case
        {:x => 123,
          :y => {:foo => "bigfoot", :bar => [3,2,1]}
        }.should_not loosely_match({
                                     :y => {
                                       :foo => /.*bar.*/
                                     }})

      end
    end

  end
end
