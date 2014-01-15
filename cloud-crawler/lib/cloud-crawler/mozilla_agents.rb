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

module CloudCrawler
  class MozillaAgents
  
#   
  # "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:20.0) Gecko/20100101 Firefox/20.0",
    # 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.18) Gecko/20110628 Ubuntu/10.10 (maverick) Firefox/3.6.18',
    # 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.122 Safari/534.30',
    # 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.218 Safari/535.1',
    # 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:5.0) Gecko/20100101 Firefox/5.0',
    # 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; WOW64; Trident/4.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; .NET4.0C; .NET4.0E; MS-RTC LM 8; Zune 4.7)',
   
  def self.random_agent
    case rand(6)
     when 0

      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:#{10+rand(10)}.#{rand(10)}) Gecko/20#{10+rand(3)}#{1000+rand(3)*100+rand(28)} Firefox/20.0"
    when 1
      "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.#{10+rand(10)}) Gecko/20#{10+rand(3)}#{1000+rand(3)*100+rand(28)} Ubuntu/10.10 (maverick) Firefox/3.6.#{14+rand(5)}"
    when 2
      ver = "#{400+rand(99)}.#{10+rand(75)}"
      "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/#{ver} (KHTML, like Gecko) Chrome/12.0.#{700+rand(90)}.#{100+rand(200)} Safari/#{ver}"
    when 3
      ver = "#{400+rand(99)}.#{rand(9)}"
       "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/#{ver} (KHTML, like Gecko) Chrome/13.0.#{700+rand(90)}.#{100+rand(200)} Safari/#{ver}"

    when 4
        "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:5.0) Gecko/20#{10+rand(3)}#{1000+rand(3)*100+rand(28)} Firefox/#{4+rand(1)}.0"

    when 5
        "Mozilla/4.0 (compatible; MSIE 8.#{rand(6)}; Windows NT 6.1; WOW64; Trident/4.0; SLCC2; .NET CLR 2.0.#{50000+rand(7000)}; .NET CLR 3.5.#{30000+rand(8000)}; .NET CLR 3.0.#{30000+rand(8000)}; Media Center PC 6.0; .NET4.0C; .NET4.0E; MS-RTC LM 8; Zune 4.#{6+rand(3)})"
    end  
    
  end
  


  def self.random_agents(num=10)
    (0...num).to_a.map { |x| random_agent }
  end

  end
  
end


