#!/bin/bash
sudo add-apt-repository -y main
sudo add-apt-repository -y universe
sudo add-apt-repository -y restricted
sudo add-apt-repository -y multiverse
sudo apt install -y xrdp
sudo systemctl enable --now xrdp
sudo ufw allow from any to any port 3389 proto tcp
#echo "<h1>Hello, World</h1>" > index.html
cat <<- EOF > index.html
<!DOCTYPE html>
<head>
	<title>Hello World</title>
  <link href="https://fonts.googleapis.com/css?family=Source+Code+Pro" rel="stylesheet">

	<style>
		body {
			background-color: #2D2D2D;
		}

		h1 {
			color: #C26356;
			font-size: 52px;
			font-family: Menlo, Monaco, fixed-width;
		}

		p {
			color: white;
			font-size: 34px;
			font-family: "Source Code Pro", Menlo, Monaco, fixed-width;
		}

		container {
			position: absolute;
			margin: auto;
			top: 0;
			right: 0;
			bottom: 0;
			left: 0;
			width: 52em;
			height: 10em;
		}
	</style>
</head>
<body>
	<container><h1>Hello World</h1>
	<p>We are live.</p></container>
</body>
</html>

EOF

nohup busybox httpd -f -p 80 &
