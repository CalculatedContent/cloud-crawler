#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TN)
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
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module CloudCrawler
  describe CookieStore do

    it "should start out empty if no cookies are specified" do
      CookieStore.new.empty?.should be true
    end

    it "should accept a Hash of cookies in the constructor" do
      CookieStore.new({'test' => 'cookie'})['test'].value.should == 'cookie'
    end

    it "should be able to merge an HTTP cookie string" do
      cs = CookieStore.new({'a' => 'a', 'b' => 'b'})
      cs.merge! "a=A; path=/, c=C; path=/"
      cs['a'].value.should == 'A'
      cs['b'].value.should == 'b'
      cs['c'].value.should == 'C'
    end

    it "should have a to_s method to turn the cookies into a string for the HTTP Cookie header" do
      CookieStore.new({'a' => 'a', 'b' => 'b'}).to_s.should == 'a=a;b=b'
    end

  end
end
