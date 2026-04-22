{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.spotify-player-wrapped-default = pkgs.callPackage ../packages/spotify-player-wrapped { };
      packages.spotify-player-wrapped = self'.packages.spotify-player-wrapped-default.override (prev: {
        force-sixel-alacritty = true;
        keymap-defaults = false;
        settings = {
          cover_img_length = 10;
          cover_img_width = 5;
          cover_img_scale = 1.8;
        };
        keymap = {
          "+".VolumeChange.offset = 5;
          "ü".VolumeChange.offset = -5;
          "*".VolumeChange.offset = 1;
          "Ü".VolumeChange.offset = -1;

          "home" = "PreviousTrack";
          "end" = "NextTrack";
          "space" = "ResumePause";
          "m" = "Mute";

          "R" = "Repeat";
          "S" = "Shuffle";
          "s s" = "SeekStart";
          "s f".SeekForward = { };
          "s b".SeekBackward = { };
          "." = "ShowActionsOnCurrentTrack";
          "_ _" = "PlayRandom";

          "backspace" = "PreviousPage";
          ": b" = "PreviousPage";
          "esc" = "ClosePopup";
          ": q" = "Quit";
          "?" = "OpenCommandHelp";
          ": h" = "OpenCommandHelp";

          ": r" = "RefreshPlayback";
          ": R" = "RestartIntegratedClient";

          "h" = "FocusPreviousWindow";
          "j" = "SelectNextOrScrollDown";
          "k" = "SelectPreviousOrScrollUp";
          "l" = "FocusNextWindow";
          "J" = "PageSelectNextOrScrollDown";
          "K" = "PageSelectPreviousOrScrollUp";
          "C-j" = "SelectLastOrScrollToBottom";
          "C-k" = "SelectFirstOrScrollToTop";

          "H" = "PreviousPage";
          "L" = "ChooseSelected";

          "left" = "FocusPreviousWindow";
          "down" = "SelectNextOrScrollDown";
          "up" = "SelectPreviousOrScrollUp";
          "right" = "FocusNextWindow";
          "page_down" = "PageSelectNextOrScrollDown";
          "page_up" = "PageSelectPreviousOrScrollUp";
          "C-page_down" = "SelectLastOrScrollToBottom";
          "C-page_up" = "SelectFirstOrScrollToTop";

          "enter" = "ChooseSelected";
          "tab" = "ShowActionsOnSelectedItem";
          "backtab" = "ShowActionsOnCurrentContext";
          "e" = "AddSelectedItemToQueue";

          ": s t" = "SwitchTheme";
          ": s d" = "SwitchDevice";
          "/" = "Search";
          ": u p" = "BrowseUserPlaylists";
          ": u i" = "BrowseUserFollowedArtists";
          ": u a" = "BrowseUserSavedAlbums";

          "g c" = "CurrentlyPlayingContextPage";
          "g t" = "TopTrackPage";
          "g r" = "RecentlyPlayedTrackPage";
          "g l" = "LikedTrackPage";
          "g L" = "LyricsPage";
          "g u l" = "LibraryPage";
          "g s" = "SearchPage";
          "g b" = "BrowsePage";
          "g e" = "Queue";
          ": o" = "OpenSpotifyLinkFromClipboard";
          "g g" = "JumpToCurrentTrackInContext";
          "g h" = "JumpToHighlightTrackInContext";

          "s t" = "SortTrackByTitle";
          "s i" = "SortTrackByArtists";
          "s a" = "SortTrackByAlbum";
          "s D" = "SortTrackByAddedDate";
          "s d" = "SortTrackByDuration";
          "s u l a" = "SortLibraryAlphabetically";
          "s u l r" = "SortLibraryByRecent";
          "s r" = "ReverseTrackOrder";
        };
      });
    };
}
