#!/bin/sh

rm -r dist
mkdir dist
rm $(find . | grep "~")
locationhere=$(pwd)
export WINEPREFIX="$locationhere/winbuild/nsis"
ubnverinit=$(bzr version-info | grep revno | sed 's/revno: //')

# Install wine

if [ ! -e /usr/bin/wine ]; then
echo "Installing wine..."
sudo apt-get update && sudo apt-get install wine
fi

if [ ! -e /usr/bin/fakeroot ]; then
echo "Installing fakeroot..."
sudo apt-get update && sudo apt-get install fakeroot
fi

if [ ! -e /usr/bin/alien ]; then
echo "Installing alien..."
sudo apt-get update && sudo apt-get install alien
fi

# Backup Wine config files

cp $locationhere/winbuild/nsis/system.reg $locationhere/winbuild/nsis/system.bak
cp $locationhere/winbuild/nsis/user.reg $locationhere/winbuild/nsis/user.bak

# Build for distros

targetbuildoslist="$(cat targetdistros)"

for targetbuildos in $targetbuildoslist
do
cd $locationhere
ubnver=$targetbuildos\rev$ubnverinit
mv ./initkern/ubninit-$targetbuildos ./unetbootin
mv ./initkern/ubnkern-$targetbuildos ./unetbootin
cp ./unetbootin/ubninst ./unetbootin/ubninst-orig
sed -i "s/replacewithubnversion/$ubnver/g" ./unetbootin/ubninst
cd $locationhere/makeself
./makeself.sh $locationhere/unetbootin $locationhere/dist/unetbootin-$ubnver.sh "UNetbootin" ./ubninst
cd $locationhere
mv ./unetbootin/ubninst-orig ./unetbootin/ubninst
mv $locationhere/unetbootin/ubnkern-$targetbuildos $locationhere/unetbootin-deb/boot/ubnkern
mv $locationhere/unetbootin/ubninit-$targetbuildos $locationhere/unetbootin-deb/boot/ubninit
cp ./unetbootin-deb/DEBIAN/postinst ./unetbootin-deb/DEBIAN/postinst-orig
sed -i "s/replacewithubnversion/$ubnver/g" ./unetbootin-deb/DEBIAN/postinst
cp ./unetbootin-deb/DEBIAN/control ./unetbootin-deb/DEBIAN/control.bak
sed -i "s/Version: 1.0/Version: $ubnver/" ./unetbootin-deb/DEBIAN/control
ubnsize=$(du -ck unetbootin-deb | grep total | sed "s/ /\n/g" | sed "s/\t/\n/g" | head --lines 1)
sed -i "s/Installed-Size: 10/Installed-Size: $ubnsize/" ./unetbootin-deb/DEBIAN/control
dpkg-deb -b unetbootin-deb
mv ./unetbootin-deb.deb ./dist/unetbootin_$ubnver\_all.deb
mv ./unetbootin-deb/DEBIAN/control.bak ./unetbootin-deb/DEBIAN/control
mv ./unetbootin-deb/DEBIAN/postinst-orig ./unetbootin-deb/DEBIAN/postinst
mv $locationhere/unetbootin-deb/boot/ubnkern $locationhere/winbuild/ubnkern
mv $locationhere/unetbootin-deb/boot/ubninit $locationhere/winbuild/ubninit
cd $locationhere/dist
fakeroot alien --scripts -r unetbootin_$ubnver\_all.deb
cd $locationhere/winbuild
cp unetbootin.nsi unetbootin-orig.nsi
cp vbooted.bat vbooted-orig.bat
sed -i "s/ubnbzrsubversionum/$ubnverinit/g" ./unetbootin.nsi
sed -i "s/replacewithubnversion/$ubnver/g" ./unetbootin.nsi
sed -i "s/replacewithubnversion/$ubnver/g" ./vbooted.bat
wine "C:\Program Files\NSIS\makensis.exe" unetbootin.nsi
mv setup.exe $locationhere/dist/unetbootin-$ubnver.exe
mv unetbootin-orig.nsi unetbootin.nsi
mv vbooted-orig.bat vbooted.bat
cd $locationhere
mv $locationhere/winbuild/ubnkern $locationhere/initkern/ubnkern-$targetbuildos
mv $locationhere/winbuild/ubninit $locationhere/initkern/ubninit-$targetbuildos
done

# Restore Wine config files

sleep 5
mv $locationhere/winbuild/nsis/system.bak $locationhere/winbuild/nsis/system.reg
mv $locationhere/winbuild/nsis/user.bak $locationhere/winbuild/nsis/user.reg