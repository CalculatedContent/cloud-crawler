#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TM)
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
# All rights reserved.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL MADE BY MADE LTD BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
require 'rubygems'
require 'bundler/setup'

$:.unshift(File.dirname(__FILE__))
require 'spec_helper'


module CloudCrawler

  class TestDsl      
     include  DslCommon
  end
  
  describe DslCommon do


      it "should compress and decompress any string" do
        str = "this is a string to compress and then decompress"
        str2 = TestDsl.new.compress(str)       
        str3 = TestDsl.new.decompress(str2)  #extra quotes are added 
        
        str.should == str3  # till has problems..with quotes
      
      end
      
      it "should compress and decompress an array or other ruby object" do
        a =[1,2,"3"]
        a2 = TestDsl.new.compress(a)       
        a3 = TestDsl.new.decompress(a2)
        
        a.should == a3  
      
      end
      
      it "should symbolize the keys of a hash" do
        a = { :hello => "world"}
        a2 = TestDsl.new.compress(a)       
        a3 = TestDsl.new.decompress(a2)
        
        a.should == a3  
      end
      
      it "should provide a UTF-8 encoded string" do
         # how check?
      end
      
      
      
   end
end
 