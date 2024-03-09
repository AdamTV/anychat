Write-Output "$WINDOWN_PFX"
Move-Item -Path $WINDOWS_PFX -Destination anychat.pem
certutil -decode anychat.pem anychat.pfx

flutter pub run msix:create -c anychat.pfx -p $WINDOWS_PFX_PASS --sign-msix true --install-certificate false
