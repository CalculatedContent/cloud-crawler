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
require 'spec_helper'

module CloudCrawler
  describe HTTP do

    describe "fetch_page" do
      before(:each) do
        FakeWeb.clean_registry
      end

      it "should still return a Page if an exception occurs during the HTTP connection" do
        HTTP.stub!(:refresh_connection).and_raise(StandardError)
        http = CloudCrawler::HTTP.new
        http.fetch_page(SPEC_DOMAIN).should be_an_instance_of(Page)
      end
      

    
    
    
      it 'should respond to ...' do
        
              # :user_agent
     # :accept_cookies?
      # :proxy_host
      # :proxy_port
#   redirect_limit
     # :read_timeout
   
      end
      
       it 'should pool connections?  ' do
         
       end
       
         it 'should provide an api agnostic response code ' do
         
       end
       
        it 'should understand cookies ' do
         
       end
       
         it 'should crawl javascript via  a browser ' do
         
       end
       
       it 'should provide json not as a page?  or a json page?' do
         
       end
       
       
    
    end
  end
end
