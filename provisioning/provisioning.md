git clone https://github.com/kurthalex/etherlife.co.git
cd etherlife.co/provisioning
touch hosts
IP_SERVER=192.168.0.0  # replace by the addressof your server
echo "[etherlifeserver]\n$IP_SERVER" >> hosts
