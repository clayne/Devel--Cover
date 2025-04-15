# Copyright 2012-2025, Paul Johnson (paul@pjcj.net)

# This software is free.  It is licensed under the same terms as Perl itself.

# The latest version of this software should be available from my homepage:
# http://www.pjcj.net

package Devel::Cover::Report::Vim;

use strict;
use warnings;

our $VERSION;

BEGIN {
  # VERSION
}

use Devel::Cover::DB;
use Devel::Cover::Inc;

BEGIN { $VERSION //= $Devel::Cover::Inc::VERSION }

use Getopt::Long;
use Template 2.00;

sub get_options {
  my ($self, $opt) = @_;
  $opt->{outputfile} = "coverage.vim";
  die "Invalid command line options" unless GetOptions(
    $opt, qw(
      outputfile=s
    )
  );
}

sub report {
  my ($pkg, $db, $options) = @_;

  my $template = Template->new({
    LOAD_TEMPLATES =>
      [ Devel::Cover::Report::Vim::Template::Provider->new({}) ]
  });

  my $vars = {
    runs => [
      map {
        run      => $_->run,
          perl   => $_->perl,
          OS     => $_->OS,
          start  => scalar gmtime $_->start,
          finish => scalar gmtime $_->finish,
      },
      sort { $a->start <=> $b->start } $db->runs,
    ],
    cov_time => do {
      my $time = 0;
      for ($db->runs) {
        $time = $_->finish if $_->finish > $time;
      }
      int $time
    },
    version => $VERSION,
    files   => $options->{file},
    cover   => $db->cover,
    types   => [ grep $_ ne "time", keys %{ $options->{show} } ],
  };

  my $out = "$options->{outputdir}/$options->{outputfile}";
  $template->process("vim", $vars, $out) or die $template->error();

  print "Vim script written to $out\n" unless $options->{silent};
}

1;

package Devel::Cover::Report::Vim::Template::Provider;

use strict;
use warnings;

# VERSION

use base "Template::Provider";

my %Templates;

sub fetch {
  my $self = shift;
  my ($name) = @_;
  # print "Looking for <$name>\n";
  $self->SUPER::fetch(exists $Templates{$name} ? \$Templates{$name} : $name)
}

$Templates{vim} = <<'EOT';
" This file was generated by Devel::Cover Version [% version %]
" Devel::Cover is copyright 2001-2025, Paul Johnson (paul@pjcj.net)
" Devel::Cover is free. It is licensed under the same terms as Perl itself.
" The latest version of Devel::Cover should be available from my homepage:
" http://www.pjcj.net

[% FOREACH r = runs %]
" Run:          [% r.run    %]
" Perl version: [% r.perl   %]
" OS:           [% r.OS     %]
" Start:        [% r.start  %]
" Finish:       [% r.finish %]

[% END %]

highlight cov_pod              ctermfg=Green cterm=bold gui=bold guifg=Green
highlight cov_pod_error        ctermfg=Red   cterm=bold gui=bold guifg=Red
highlight cov_subroutine       ctermfg=Green cterm=bold gui=bold guifg=Green
highlight cov_subroutine_error ctermfg=Red   cterm=bold gui=bold guifg=Red
highlight cov_statement        ctermfg=Green cterm=bold gui=bold guifg=Green
highlight cov_statement_error  ctermfg=Red   cterm=bold gui=bold guifg=Red
highlight cov_branch           ctermfg=Green cterm=bold gui=bold guifg=Green
highlight cov_branch_error     ctermfg=Red   cterm=bold gui=bold guifg=Red
highlight cov_condition        ctermfg=Green cterm=bold gui=bold guifg=Green
highlight cov_condition_error  ctermfg=Red   cterm=bold gui=bold guifg=Red

sign define pod              linehl=cov texthl=cov_pod              text=P 
sign define pod_error        linehl=err texthl=cov_pod_error        text=P 
sign define subroutine       linehl=cov texthl=cov_subroutine       text=R 
sign define subroutine_error linehl=err texthl=cov_subroutine_error text=R 
sign define statement        linehl=cov texthl=cov_statement        text=S 
sign define statement_error  linehl=err texthl=cov_statement_error  text=S 
sign define branch           linehl=cov texthl=cov_branch           text=B 
sign define branch_error     linehl=err texthl=cov_branch_error     text=B 
sign define condition        linehl=cov texthl=cov_condition        text=C 
sign define condition_error  linehl=err texthl=cov_condition_error  text=C 

function! CoverageOld(filename)
endfunction

function! CoverageValid(filename)
endfunction

" The signs definitions can be overridden.  To do this add a file called
" devel-cover.vim at some appropriate point in your ~/.vim directory and add
" your local configuration commands there.
" For example, I use the vim solarized theme and I have the following comamnds
" in my local configuration file ~/.vim/local/devel-cover.vim:
"
" ----------------------------------------------------------------------------
"
"    let s:fg_cover = "#859900"
"    let s:fg_error = "#dc322f"
"    let s:bg_valid = "#073642"
"    let s:bg_old   = "#342a2a"
"
"    let s:types = [ "pod", "subroutine", "statement", "branch", "condition", ]
"
"    for s:type in s:types
"        exe "highlight cov_" . s:type .       " ctermbg=0 cterm=bold gui=NONE guifg=" . s:fg_cover
"        exe "highlight cov_" . s:type . "_error ctermbg=0 cterm=bold gui=NONE guifg=" . s:fg_error
"    endfor
"    exe "highlight SignColumn ctermbg=0 guibg=" . s:bg_valid
"
"    " highlight cov ctermbg=8 guibg=#002b36
"    " highlight err ctermbg=0 guibg=#073642
"
"    function! s:set_bg(bg)
"        for s:type in s:types
"            exe "highlight cov_" . s:type .       " guibg=" . a:bg
"            exe "highlight cov_" . s:type . "_error guibg=" . a:bg
"        endfor
"        exe "highlight SignColumn ctermbg=0 guibg=" . a:bg
"    endfunction
"
"    function! CoverageValid(filename)
"        call s:set_bg(s:bg_valid)
"    endfunction
"
"    function! CoverageOld(filename)
"        call s:set_bg(s:bg_old)
"    endfunction
"
" ----------------------------------------------------------------------------

let s:config = findfile("devel-cover.vim", expand('$HOME/.vim') . "/**")
if strlen(s:config)
    echom "Reading local config from " . s:config
    exe "source " . s:config
endif

let s:types = [
[%- FOREACH type = types -%] "[%- type -%]",[%- END -%]
[%- FOREACH type = types -%] "[%- type -%]_error",[%- END -%]
 ]

[%- MACRO criterion(file, crit, error) BLOCK %]
\         '[% crit %][% error ? "_error" : "" %]': [
    [%- criteria = cover.file("$file").$crit -%]
    [%- FOREACH loc = criteria.items.nsort -%]
        [%- cov = 0 -%]
        [%- FOREACH l = criteria.location("$loc") -%]
            [%- IF error ? l.error : l.covered -%] [% loc -%],[%- cov = 1; LAST; END -%]
        [%- LAST IF cov; END -%]
    [%- END -%]
 ],
[%- END %]

let s:coverage =
\ {
\[% FOREACH file = files %]
\     '[% file %]':
\     {
[%- FOREACH type = types; criterion(file, type, 0); criterion(file, type, 1); END %]
\     },
\[% END %]
\ }

let s:cov_time = [% cov_time %]

function! s:coverage_for(filename)
    let s:fn_len = strlen(a:filename)
    for s:cf in keys(s:coverage)
        let s:f = substitute(s:cf, "^blib/", "", "")
        let s:match_pos = match(a:filename, s:f . "$")
        if s:match_pos >= 0 && s:match_pos < s:fn_len
            return s:coverage[s:cf]
        endif
    endfor

    echom "No coverage recorded for " . a:filename
    return {}
endfunction

let s:signs    = {}
let s:sign_num = 1

function! s:add_coverage_signs(filename)
    let s:cov = s:coverage_for(a:filename)
    if !len(keys(s:cov))
        return
    endif

    if getftime(a:filename) > s:cov_time
        echom "File is newer than coverage run of " . strftime("%c", s:cov_time)
        call CoverageOld(a:filename)
    else
        call CoverageValid(a:filename)
    endif

    if !exists("s:signs['" . a:filename . "']")
        let s:signs[a:filename] = {}
    endif
    let s:s = s:signs[a:filename]

    for s:type in reverse(copy(s:types))
        for s:line in s:cov[s:type]
            if !exists("s:s['" . s:line . "']")
                let s:id = s:sign_num
                let s:sign_num += 1
                let s:s[s:line] = s:id
                exe ":sign place " . s:id . " line=" . s:line . " name=" . s:type . " file=" . a:filename
            endif
        endfor
    endfor
endfunction

function! s:del_coverage_signs(filename)
    if exists("s:signs['" . a:filename . "']")
        let s:s = s:signs[a:filename]
        for s:line in keys(s:s)
            exe ":sign unplace " . s:s[s:line]
        endfor
        let s:signs[a:filename] = {}
    endif
endfunction

let s:filename = expand("<sfile>")
function! s:uncover(sourced)
    if a:sourced == s:filename
        call s:del_coverage_signs(expand("%:p"))
    endif
endfunction

command! -nargs=0 Cov   call s:add_coverage_signs(expand("%:p"))
command! -nargs=0 Uncov call s:del_coverage_signs(expand("%:p"))

augroup devel-cover
    au!
    exe "au SourcePre " . expand("<sfile>:t") . " call s:uncover(expand('<afile>:p'))"

    " show signs automatically for all known files
    for s:filename in keys(s:coverage)
        exe "au BufReadPost " . s:filename . ' call s:add_coverage_signs(expand("%:p"))'
        let s:f = substitute(s:filename, "^blib/", "", "")
        if s:filename != s:f
            exe "au BufReadPost " . s:f . ' call s:add_coverage_signs(expand("%:p"))'
        endif
    endfor
augroup end

Cov
EOT

1

__END__

=head1 NAME

Devel::Cover::Report::Vim - Backend for displaying coverage data in Vim

=head1 SYNOPSIS

 cover -report vim

=head1 DESCRIPTION

This module provides a reporting mechanism for displaying coverage data in
Vim.  It is designed to be called from the C<cover> program.

By default, the output of this report is a file named C<coverage.vim> in the
directory of the coverage database.  To use it, run

 :so cover_db/coverage.vim

and you should see signs in the left column indicating the coverage status of
that line.

The signs are as follows:

 P - Pod coverage
 S - Statement coverage
 R - Subroutine coverage
 B - Branch coverage
 C - Condition coverage

The last of the criteria, in the order given above, is the one which is
displayed.  Correctly covered criteria are shown in green.  Incorrectly
covered criteria are shown in red.  Any incorrectly covered criterion will
override a correctly covered criterion.

If the coverage for the file being displayed is out of date the a function
called CoverageOld() is called and passed the name of the file.  Similarly,
for current coverage data file CoverageValid is called.

Signs may be overridden in a file named devel-cover.vim located somewhere
underneath the ~/.vim directory.

For example, I use the solarized theme and keep the following commands in my
local configuration file ~/.vim/local/devel-cover.vim:

 let s:fg_cover = "#859900"
 let s:fg_error = "#dc322f"
 let s:bg_valid = "#073642"
 let s:bg_old   = "#342a2a"

 let s:types = [ "pod", "subroutine", "statement", "branch", "condition", ]

 for s:type in s:types
     exe "highlight cov_" . s:type .       " ctermbg=1 cterm=bold gui=NONE guifg=" . s:fg_cover
     exe "highlight cov_" . s:type . "_error ctermbg=1 cterm=bold gui=NONE guifg=" . s:fg_error
 endfor
 exe "highlight SignColumn ctermbg=0 guibg=" . s:bg_valid

 " highlight cov ctermbg=8 guibg=#002b36
 " highlight err ctermbg=0 guibg=#073642

 function! s:set_bg(bg)
     for s:type in s:types
         exe "highlight cov_" . s:type .       " guibg=" . a:bg
         exe "highlight cov_" . s:type . "_error guibg=" . a:bg
     endfor
     exe "highlight SignColumn ctermbg=0 guibg=" . a:bg
 endfunction

 function! CoverageValid(filename)
     call s:set_bg(s:bg_valid)
 endfunction

 function! CoverageOld(filename)
     call s:set_bg(s:bg_old)
 endfunction

This configuration sets the background colour of the signs to a dark red when
the coverage data is out of date.

coverage.vim adds two user commands: :Cov and :Uncov which can be used to
toggle the state of coverage signs.

The idea and the vim template is shamelessly stolen from Simplecov-Vim.  See
https://github.com/nyarly/Simplecov-Vim

=head1 SEE ALSO

 Devel::Cover
 Simplecov-Vim (https://github.com/nyarly/Simplecov-Vim)

=head1 BUGS

Huh?

=head1 LICENCE

Copyright 2012-2025, Paul Johnson (paul@pjcj.net)

This software is free.  It is licensed under the same terms as Perl itself.

The latest version of this software should be available from my homepage:
http://www.pjcj.net

The template is copied from Simplecov-Vim
(https://github.com/nyarly/Simplecov-Vim) and is under the MIT Licence.


The MIT License

Copyright (c) 2011 Judson Lester

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
