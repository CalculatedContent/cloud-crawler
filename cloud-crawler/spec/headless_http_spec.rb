require 'cloud-crawler'
require 'uri'
require 'fakeweb'

module CloudCrawler
  describe HTTP do

    describe "fetch_page" do

      it "should evaluate javascript if headless option is selected" do

        html = <<-HTML
            <html xmlns="http://www.w3.org/1999/xhtml"><head></head>
                <body id="body">
                    <script>
                        document.getElementById('body').appendChild(document.createElement('div'));
                    </script><div></div>
            </body></html>
        HTML
        FakeWeb.allow_net_connect = true
        http = CloudCrawler::HTTP.new( {
            verbose: true,
            headless: true,
            headless_wait: 1
        } )
        page = http.fetch_page("http://localhost/")
        page.code.should == 200
        page.body.should == html.delete(' ')
        FakeWeb.allow_net_connect = false
      end
    end
  end
end
