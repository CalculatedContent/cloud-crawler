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

require 'active_support/inflector'
require 'active_support/core_ext'
require 'zlib'
require 'base64'
require 'json'

#  should recursively compress and decompress
# see batch job 180

# for exmaple, arrays of hashes should be symbolized

# i would prefer the bulk of this to be done in lua, but...

module CloudCrawler
  module DslCommon
   
    def decompress(str)
      json = Zlib::Inflate.inflate(Base64.decode64 str)

      obj = JSON.parse(json)
      obj.symbolize_keys! if obj.kind_of? Hash
      
      # TODO: deep decompression, recursively if possible
      # obj.map! { |x| x.symbolize_keys! } if obj.kind_of Array
      obj
    rescue => e
      p e.message
      p e.backtrace
      end

    def compress(obj)
      # TODO: deep compression,  recursively if possible
      # array.compact! if obj.kind_of Array
      Base64.encode64 Zlib::Deflate.deflate(obj.to_json)
    end

  end
end
