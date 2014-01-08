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
require 'httparty'
require 'cloud-crawler/page'
require 'cloud-crawler/logger'

module CloupdCrawler
  class HttpParty
    
    # TODO:  fetch_results
    #  add authentication
    
    # Maximum number of redirects to follow on each get_response
    REDIRECT_LIMIT = 5
    

    # CookieStore for this HTTP client
    attr_reader :cookie_store
    
    def initialize(opts = {}, user, pass)
      @opts = opts
      @user = user
      @pass = pass
      @cookie_store =  CookieStore.new(@opts[:cookies])
    end
    
    def authenticate
      
    end
    
    
    def is_authenticated?
      
    end
    
    
    # TODO:  add id for root referer so cookies can be saved
    def fetch_result(url)
      begin
        url = URI(url) unless url.is_a?(URI)
        json = {}.to_json
       
      rescue Exception => e
        if verbose?
            LOGGER.info e.inspect
            LOGGER.info e.backtrace
        end
       
       return JSON.parse(json)
      end
    end

    #
    # The maximum number of redirects to follow
    #
    def redirect_limit
      @opts[:redirect_limit] || REDIRECT_LIMIT
    end

    #
    # The user-agent string which will be sent with each request,
    # or nil if no such option is set
    #
    def user_agent
      @user_agent ||= @opts[:user_agent]
    end
    
    def user_agent=(ua)
      @user_agent = ua
    end

    #
    # Does this HTTP client accept cookies from the server?
    #
    def accept_cookies?
      @opts[:accept_cookies]
    end

    #
    # The proxy address string
    #
    def proxy_host
      @opts[:proxy_host]
    end

    #
    # The proxy port
    #
    def proxy_port
      @opts[:proxy_port]
    end

    #
    # HTTP read timeout in seconds
    #
    def read_timeout
      @opts[:read_timeout]
    end
    
    
    def verbose?
      @opts[:verbose]
    end


    private

   
  
    #
    # Allowed to connect to the requested url?
    #
    def allowed?(to_url, from_url)
      to_url.host.nil? || (to_url.host == from_url.host)
    end

  end
end
