require 'sinatra'

set :port, 80
get '/' do
    html = <<-HTML
        <html>
            <head></head>
            <body id="body">
                <script>
                    document.getElementById('body').appendChild(document.createElement('div'));
                </script>
            </body>
        </html>
    HTML
    html
end

