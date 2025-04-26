## if failed running ./dotnet-install.sh
mkdir -p /apps/dotnet-sdk2.1
tar -xzvf dotnet-sdk-2.1.818-linux-x64.tar.gz -C /apps/dotnet-sdk2.1
export DOTNET_ROOT=/apps/dotnet-sdk2.1
export PATH=$DOTNET_ROOT:$PATH