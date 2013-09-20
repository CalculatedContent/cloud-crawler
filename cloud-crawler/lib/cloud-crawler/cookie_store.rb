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
require 'delegate'
require 'webrick/cookie'
require 'cloud-crawler/logger'

class WEBrick::Cookie
  def expired?
    !!expires && expires < Time.now
  end
end

module CloudCrawler
  class CookieStore < DelegateClass(Hash)

    def initialize(cookies = nil)
      @cookies = {}
      cookies.each { |name, value| @cookies[name] = WEBrick::Cookie.new(name, value) } if cookies
      super(@cookies)
    end

    def merge!(set_cookie_str)
      begin
        cookie_hash = WEBrick::Cookie.parse_set_cookies(set_cookie_str).inject({}) do |hash, cookie|
          hash[cookie.name] = cookie if !!cookie
          hash
        end
        @cookies.merge! cookie_hash
      rescue
      end
    end

    def to_s
      @cookies.values.reject { |cookie| cookie.expired? }.map { |cookie| "#{cookie.name}=#{cookie.value}" }.join(';')
    end

  end
end
