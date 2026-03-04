Yesterday 19:36
We've got. Two sets of PR. 

How lensing That process can be attached and also what we have to bear in mind is that With the network firewall projects, you know, We've got multiple developers at times trying to update The same Project, Which in its own has result challenges. 

You know, We we, we kind of instances we had, like, state, for instance, pool request. 

Uh, what do you call them conflicts? 

You know where you raise the pool request? 

Next time you go to have a look, Another pool request has jumped in, approved, and merged, which sort of like creates the conflict in yourself. 

Obviously, the time frame increases, you know. 

Just Deploy a symbol configuration, you know, what's going into production? 

So, We now talk to ourselves. 

Okay, before I, I get to that parts also to to the commission, this resources. 

We then have to follow that same to fold process In the in the reverse order. 

You know again, Don't challenges. 

In fact, in the past, we've had instances. 

Say for instance, you, you, the commission, your own project, you, you delete, delete that resources like load balancers, Which is associated natural interfaces, and so on and so forth. 

You forget to remove Those the penalties you've added to the network Regional network firewall project. 

So, when that runs the textile, it fails because it's unable to resolve what's called those dependencies, you know. 

So now, again, Out of that challenge, you know, furthermore, world would then think about say, for instance, that that, would you know, project from from the security perspective. 

Do we really want a lot of developers Updating that project? 

So, As part of? 

So As part of our devil is to streamline that process. 

What we now came up with as part of the Golden Path And what's going devil. 

Basically, all you have to do as part of that project that you're using to deploy and these things from your Ingress. 

Basically, all you have to do as part of that project that you're using to deploy and these things from your Ingress. 



Yesterday 19:40
He pulls Those data from SSM parameter store, Create the required Network firewall. 

I thought you said to the correct, uh, what's called rural group? 

I usually If you remember with Ingreso igress patterns with God different types. 

Yep, so those rural groups That are created, I might, to those Ingress egress type. 

So there's a relationship there. 

Yeah, so again, Once an associated basically what that pipeline runs once that, that It so the jet dispel pipeline that Deploys the resources declines between the original Network firewall. 

What was that? 

Was our uses? 

Our module picks up your your data from message and parameters to stop Builds that firework Applies it to the attaches it to the to the right group And your your good to go. 

So, what that does is that That removes The additional efforts required to manage and maintain your configuration In the network Firewall. 

Cool Jen. 

So, as you can see, A lot of the challenges that I mentioned We've been able to stop solve by streamlining that was called that process. 

Uh, this is a it was going to diagram that sort of like, Describes, But I'll just explained, um, before we actually look at the modules themselves. 

So, again, it's quite straightforward. 

Like, I said. 

So, Uh, developer defines firewall rules that are form project using a configuration variable. 

This is our module, The dynamic Moscope parameter, Dynamic group parameter module. 

This is our modification. 

Basically, all it does is it generates a unique, Uh, using a timestamp. 

Plus, You was called what's called what's called combination. 

I also explain that when we go through the module, so again that is used with the data that you've passed in to create The bundle and the rule configuration bundle and data bundle that is pushed SSM parameter store. 

And again, It is managed using a hierarchical Ssm part. 

So for each That you deploy. 

Sorry for each rule that you write to SSN that is deployed into your firewall. 

You can trace it using this path, which will look at Start Again. 

This is your data in the ews parameters store, you know, again. 

Configuration objects, thought, and things like the action, the protocol, And you're like five years used to create IP sets and port sets used to configure network firewall rules in either of us. 

So, this is the automation pattern I was telling you about in relation to How each regional network fire will Jenkins pipeline when he runs. 

It goes through the process I talked about with SSN parameter. 

Data From the US was for using the the golden at ayak AWS network fire World Dynamic module. 

It transforms that Json data to recata format Goes through the process of Actually attaching it to A rural group, which is download your stats associated to a network firewall policy, Uh, which is then activated by the, But by the actual and what's called deployed firewall itself, so it's quite straightforward, so I'm just going to go to the the module and to show you what it looks like, but if I do that again, um, this is the readme file in the network file wall repository, Uh, where we And store data or code related to Ingress. 

E what's called egress It? 

Shared description has been added here. 

That basically points you to How to use that module to achieve at and network firewall rule Automation. 

So, again, if I just click on here. 

It takes us there. 

What's called basically? 

Now, again, this is just provides like an overview of wall with talked about. 

So this basically Introduction say what the module, what score is? 

What's called is useful. 

So again, what the modes does? 

What will talked about things like accepted firewall rules configuration as inputs parameters with diglosed education for traffic control, Uh, generating unique identifier seeds for each rule based on Einstein's, Uh, story rule. 

Configuration in SSN parameter. 

Stop with a hierarchical Bat structure, Um, including real details into Json format for consumption by Downstream automation, managing rules metadata, including things like your IP addresses, your ports, your protocol, and traffic was called fluid Direction. 

Then again, This is sort of like provides like a step-by-step process of how that workflow Commences. 

And so, again, Straightforward. 

The configuration with deploy includes attributes, such as like action like things like past, but as a graphic droplet traffic send out and I learned reject. 

So on and so forth. 

We've got the architectural pattern again and the traffic pattern type. 

If you can see, uh, for for those that work with the Ingress egress regularly? 

As you can see, this is us very similar to the Patterns. 

Define the different types of pattern Ingress Ingress patterns, so we've got things that protocol IP list. 

So on, and so forth. 

If I go back if I just go down to the next level, which is, uh, to exercise parameter store organization. 

Now, this is that hierarchical order. 

I was telling you about to get, So we've got That part, so followed by the region, then the the flow direction is really an Ingress on egress. 

Then we got specific atoms And and it gives you remember those architectural patterns that I mentioned have met. 

Directly to the rural groups Used by The the the So used to store your store your fire rule. 

So, so, for instance, this is an example part. 

So again. 

As you can see, this is This is the architectural pattern, and we'll talk about why we've got this. 

And here, And later on, as we look at the actual code itself. 

So, now we get This last. 

Basically, all that defines Is. 

Basically. 

So, Every single group? 

So, Every single group and related to network firewall start the necessary stop. 

This based name Uniquely identifies the content of that rule, Uh, if I scroll further down below, here's a good example. 

Another example of The data Sample data that is pushed SSN parameter store. 

So, you got things like again? 

The action on the flow architectural pattern, A support list and destination partners was concerned, and so forth. 

No, again, I, I was going to go through this again, as it's just basically Explains how the the the rules that generated, And then other rules are generated by prune. 

The SSN parameter store data down To create a specific group, which is then attached to the network file. 

So, scrolling down Again, This is just The pipelines. 

Links to the various pipelines that you can run. 

So, for instance, if I deploy the pattern. 

It was going what's going on, but after I've gone through the process that I've just described, you know, My code is my parents match like, I just have to do to enable or activate. 

My room is to come here and run the pipeline that corresponds to the region will have deployed my resources. 

This is just Some key features you know. 

Was that we've talked about, um, area? 

So we've talked about how each unix and save is generated. 

And remember, I mentioned, I mentioned because I don't think I talked about the importance of the Rook, which I'll show you shortly. 

So great! 

Further down, and one thing to note is the rule tag and what's called truncation. 

I think when I show you the module, I will explain again how The logic that derives the root type, how it comes to that. 

Conclusion These are things like, uh, how to define your individual IP addresses And in network room that represents the range of IP addresses? 

And if we scroll further down, there's various different examples. 

Use case in various configurations, so allow it was, for instance, around ecos http traffic as an example. 

So so on and so forth. 

So, um, I will make this available what's called in the chat. 

Uh, yeah, so I'm just trying to think It points to notes. 

Yeah, so, um, let me know. 

Go past this. 

What I talked about earlier, well, you know. 

It regards to the same generation here, Um, The the reason why we insist that the It always be a number When you roll it once, but when you roll what's for, run your project, and when you create your project, We we, we, we, we had to look for a way to generate a unique set, Which is specific And eat through What's called within a rule group And the only way we could do that was to use an instance of a Unix time, start stand, And then Of every object defines within a project Consideration parameters To ensure That that value we, you also unique. 

So, this is basically what this explains, so they allowed values are integers, So, But is this is not allowed? 

Okay, Uh. 

Also, what we've talked about again is the activation timeline again. 

Say, if you need to activate your rule or gently, once you've push your your your your configuration data extract. 

You can identify the pipeline, run it, and automatically that shoulder. 

Activate your rule No, and again the points. 

Note is something called the service identifier With the service identifier for Ingress, egress, and pattern projects? 

They are unique. 

The values. 

So As part of our deployment, we wanted in a way to Correlates To a project. 

So, this is where the service identifier comes in, so the service, uh, identifier is used to create the Baseline. 

Remember the base names I mentioned earlier, so it's used to create that basement. 

So, let me just go up and show you. 

Another unit timestamp Beast made. 

Let me see if I can't find it. 

Yeah, The rule tag, So I'm sure I'll show you the wrong things. 

Sorry. 

So this is the rule time. 

Yeah. 

So this service identifier And the at L's and sdlc is used to. 

I did. 

It's five or map each rule to what's going to a specific. 

What's going to specific project? 

Yeah. 

Also, What's going within this reading? 

Uh, you can find things like after you that was called. 

Deploy your Suricata rules Via automation. 

You can actually query AWS To see Was called to find your rules as well as well. 

So, This is an example by AWS Cli, which has been included in this treatment for it to verify that your configuration is actually okay. 

So, so, so, so, yeah? 



Yesterday 19:55
So, so, so, so, yeah? 



Yesterday 19:55
Uh, let me just go to the Osborne. 

Go to the module. 

Yeah, so this is what the module was called. 

Looks like, so I'll just click on one of the examples. 

So, again, it's Christ is great forward. 

So, um, The, the, the SSM configuration, is just a map of object. 

So each, uh, object Within that Mark represents To configuration specific to one rule. 

So, in this particular instance, we've got one, two, three. 

So, we've got three rules associated In this particular project. 

You guys go further down, so this is where We call our module. 

And then we pass The SSM Figuration. 

And again, this is a service identifier. 

Okay. 

Okay, So if I just go to the actual module itself, so, And again, it was going to spy straightforward. 

So, the data that you pass in. 

Remember, I said, the the, the, the, the, the state, and the rule type their dynamically generated. 

So, this is basically What's for, what this does. 

So it goes through Every configuration object Generates an attaches. 

And they said, and the rule was called attribute. 

But if I just spoke further down, as you can see For each of those rules, This is Where the Ssm A little part. 

This is how instant Dynamically generated. 

Um, As discussed area, so we've got like the region we've got the flow Direction. 

We've got extra pattern, and then finally, we've got that rule tag that I mentioned earlier on. 

What's the time now? 

What's the time now 1428? 

I think I should have enough times. 

What's going to run it just to show you guys, Um, fact? 

I'll do that at the end of that data. 

How that data I store the next parameters store? 

So, so this is a basically. 

So, um, again, And it regards to The the the requirement is variable requirements, Uh, we've used variable side validation to ensure that The the data Uploaded to access some parameter store Is actually valid and also in a format that the other project and consume Without screwing Arrow. 

To deploy your network firewall rule, I mean, I'm not going to go through all a bit more. 

I'm just going to show you like a quick, uh, what's called Description? 

Some of the validation. 

So, um, so a good one, is this? 

So, this is the actual Circle. 

The flow Direction, Which again deterans where that is Ingress or egress, or whether is bi-directional. 

So, again, These are the allowed inputs, Uh, if I also scroll further down, you can see things like The validation of the Architectural pattern Acceptable architectural pattern, So we've got like the internet English to TPS, Uh, we've got like B2B in West NS, and so on, and so forth. 

Yeah, for instance, we've got the actions, you know, validating? 



Yesterday 21:35
And is it not difficult? 

And is it not difficult? 

I'm going to do just die please that I'm searching for. 

Okay, let me see. 

Okay, so That does decide that TF, right? 

Cider.tf, you have added this, okay, where is, where is our that is Dot? 

Okay, so you have updated saw third answer. 

Okay, those things are here. 

Now, next thing is go to Squid. 

Okay, me too. 

This should be here Ctras. 

It is not here. 

Let me try the UAT and P. 

Okay, so you see here, you added this one this line. 

Okay, Controllers, And you added only in local net. 

You should add to 10 apple cider factor. 

Okay, let me see this energy. 

Now, it is not. 

Here, you have to add it wherever the prod oriential properties That is red. 

Okay, you added only the three. 

Okay, so, and you should add this phone. 

Also, Hcl tenable siders like this also Okay. 

After this line, each line, Um, you should add. 

Okay, give it a ticket number on top of this one, Okay. 

Give it here. 

Give it here. 

Okay, okay, and then use this tenable and three. 

Once you add it to local net, you should add to 10 apples headers too. 

Okay, Okay, And add for proud as well. 

After this line, I have what products. 

Okay, so don't you. 

Just mention in the comment itself. 

New VPN slided for Need to change. 

The only thing that you have to change here. 

Yes, Okay, you still have to update for u80 for 10 apple cider and then, for, Um, Um, it will be the same thing you have for local length. 

And then I will send it okay. 

But But Yeah, one more thing. 

I mean, I just want to share my screen. 

Yeah, yeah, Yeah, So that vulnerability thing that I had mentioned I was having this discussion with Matt on on the vulnerabilities that We probably have. 

So, how we are working in that area? 

Are we taking? 

This was the dashboard that we were working on, but this is for complete issue or mod. 

We have for all the teams that we have. 

We are on boarding different teams, but for Nimbers, I say, We have two criticals, and these are the highs, And these are the mediums and laws, And when I see, Like, where This vulnerabilities are I, I see Thousand I agent nodes. 

So, is that something that we take care of Israel Because I, I don't see any other one repeats showing in any other thing? 

It's just a thousand high Enterprise agent notes. 

These are waste finding actually so. 

I was thinking do. 

Do we have any plans like RV monitoring, the infraid that we are deploying, or the services that we are deploying? 

Are we monitoring the vulnerable please that data there in those and how to be fixing those? 

Come again, Is I was saying that these are vulnerabilities From visa Nisni. 

So, I see we have two criticals and this much of high and medium and lows. 

So okay, I was having this conversation with Matt on one Liberty. 

He's like the infra and the services that we had deploying. 

Uh, How many one entities are there? 

And are we fixing those two? 

Are we tracking those are not? 

So, this is the this was a cumulative dashboard that we are working on, But for numbers, I see these. 

And when I come into the details, I All these wanted. 

These are on thousand high Enterprises and nodes. 

Yeah, because we will be like moving away in the next o'clock month. 

Let's take note Are there anything? 

That is, I haven't found. 

I haven't found anything else, but Can you list only the numbers? 

Yeah, these are limbas one only. 

I was just working on automating the report an email report. 

So, Oh, was it? 

Check. 

It was here. 

Yes, uh, There are still discrepancies in the report, but I'm just trying to fix this, So this will just give us the wiz report for Nimbus. 

Okay, it can be triggered like weekly, and it can show us the trend as well. 

Uh, okay. 

In the report, we can see the trend, like, for Nimbas, how many decreased in one month, How many were fixed, those kind of things. 

So, we're just automating this. 

So, will this be helpful? 

It's if a sneak, and with report for members team, we are going on weekly basis. 

Do we want those I, I can? 

I can hide those, So I'm fixing this required here, but I think that data could be helpful. 

How come you get it? 

No, I'm just automating this. 

No, I'm just automating this. 

I'm working on creating this. 

So, what we did is, I've written a Lambda, Uh, okay, which is making API calls to vis and snake, And it is Is based on that. 

This, Just sending the notification Okay, okay, yeah, Okay, then send it to the team. 

What are those two criticals? 

Do you know that This one again if you see critical one and two? 

This is again on thousand or only. 

What is the description? 

Also The description. 

We will have to look into the wedge portal, so this is just the numbers that we get. 

Uh, yeah, okay, okay, then we can raise tickets can be not at this moment. 

Um, because we don't, we don't have. 

So, Do you have access to think, Uh, To this portal? 

This portal. 

Yes, you sneak sneak, I think. 

Yeah, can you share me in the link? 

Yeah, I will share the link. 

Yeah, and take a look, and I will open ticket if needed. 

Yeah, I think if you have, If we are doing finding out Tickets, then probably someone could pick. 

Yes, okay. 

This is a sneak and Sneak is I used for our code scanning in the terraform codes. 

Yeah, I know, I know, yeah, it doesn't scan for the environment action and what I want, And this one. 

Oh, we have access to it. 

Okay, I'll I'll take a look, and the organization does not agree. 

You don't have mission to access it, Who give you accessory. 

I will share the process. 

I mean, it's, it's probably from sale point only, so I will share the role name. 

Okay, yes, I need that, uh, just One more question. 

So, yeah, actually. 

I needed some technical suggestions here. 

So, it's a basic one. 

I, I should be able to help. 

So, this is what publishing creating that dashboard. 

And this is what is sending us the email, Uh, but this right now, we have a API Gateway, and this dashboard is accessible via internet, and I wanted to restrict that access. 

We have already done So, P. 

We have already done So. 

P type issuing.cloud ldap. 

We have used to restrict the identity Network wise restriction if I want to implement, Uh. 

Do you have any suggestion around that how we can do that? 

Um, okay, Is this this API Gateway? 

So, this dashboard, you know, this API Gateway is not public API. 

Yes, okay, the URL that we have. 

This is accessible why the internet, Uh, yeah, dashboard that you see. 

So this is accessible internet, although we have done the identity restrictions. 

So it does ask us username and password, yes, but I wanted to implement the network, uh, restrictions, as well. 

Like, only the corporate traffic should be able to access this URL. 

So, if I want to do that, I was thinking, like, probably we can restrict the Ingress. 

Who owns you? 

Are You say that URL is available on the internet, right, that you are? 

Where is the dnf number The DNS See when you type something? 

Any URL, see? 

That is, that is not like It is not a complete key name recorder. 

It is just a Oh ELP or CLB recomb that you have. 

So, if you want actually to proceed in that way that you are saying, then you should have a Ingress at the and allow only the traffic somehow IPS And allow it through shade. 

I think, Yeah, since you are going to read all that shared PCA environment, you have to have side PC, Um, thing, and then do it. 

It's blocked. 

It's blocked. 

I, I think that that is something we might do in future because this is the POC That is the way and whatever you set this correct. 

That illness setup is needed, and You can allow only the there is GPS top sellers in our link, and you have to use that to allow only those IPS will be allowed to access that URL. 

Okay, Okay, and you if you need it again on the internet that will be completely different In scientifically Or who you are going to unlock At this moment. 

You say that it is available on the internet. 

Yes, do you need me to log into VPN to access this URL? 

Uh, I think that that. 

That would be a good thing. 

Yeah, that if that is the good thing, then GPN pops that there is a perfect list. 

Take a look at the previously that that is the that is the lid that you should download the firewall rule. 

Yeah, okay, yes, Gpn pop-siders? 

Yes, okay, so that that is the thing that, and land all land wants you drive, and that will be the list of IPS that you will be getting this whole side piece where I can okay in such PCI prefix list. 

Can I find this there To go to VPC? 

Yeah, yeah, VPC. 

There will be managed prefix list. 

Okay, okay If it's list and and the G scalar IP is. 

If I use scalar IP is when you don't log into VPN, it will be the scalar writing okay. 

In that case, if you don't want to use GPM pop side address, there is scalar 5. 

List clicks list already done this so you can use that. 

So that is, like, all our Laptops will be on Z scalar if you don't log it to VPN. 

It will be redirected through Z Us. 

Is that is also okay? 

Whoever is the one and of the tool? 

Which tool you should ask them this question. 

So, whether you want the people who logged into VPN to access this URL or you want, allow them to um from our laptop. 

I mean, this issue will laptop you want them to be accessed from this issued laptop. 

But again, I'm saying this, if you are allowing these color, it is a wide range of list so that anybody who uses, I think multiple clients uses it, so anybody who uses this cannot will be able to access that URL. 

Okay, but again, if they know that you are all, they will be accessing it. 

Okay, so GPN pop cider for VPN and VPN, yeah? 

Non VPN, but. 

Okay, I? 

I think This should work Is also good. 

Fun. 

I think I will use. 

I'll use the system. 

Okay, I want to be yours that he is not doing it. 

Okay, that's it, right? 

Yeah, thank you. 

Yes, money. 

Thanks. 



Yesterday 21:53
Thanks. 



Yesterday 21:53
Thank you. 

Yeah. 



18:36
Question is. Really intended to get you the team members ready for that event. 

Um, and what comes after that. 

So, this is not a training session. 

