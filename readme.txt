A simple script to download LoC (Library of Congress) audio archives and
transcripts and metadata locally for further processing.

Requires LWP::Curl, HTML::TreeBuilder::XPath, JSON.

Which should be fixed.  LWP::Curl is nice but takes a lot of dependencies.

This is a part of a larger LoC Slave Narratives audio cleanup project.

Run:

./download_loc_audio.pl 'https://www.loc.gov/audio/?c=150&fa=subject:slave+narratives&fo=json'

To download everything to the 'data' directory.  Will take 8GB.

